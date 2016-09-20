# -*- coding: utf-8 -*-

# AWS Lambda function to mirror an on-premises DNS to Route 53 private hosted zone
# with allowing to mirror into a hosted zone with different origin
# (e.g. mirror 'activedirectory.example.org' on-premises zone to 'example.org' Route 53 zone)

# This script is a fork of https://github.com/awslabs/aws-lambda-mirror-dns-function
# Modification made by Sorah Fukumori
#
#  Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License"). You may not
#  use this file except in compliance with the License. A copy of the License is
#  located at
#      http://aws.amazon.com/apache2.0/
#
#  or in the "license" file accompanying this file. This file is distributed on
#  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
#  express or implied. See the License for the specific language governing
#  permissions and limitations under the License.


import dns.query
import dns.zone
import dns.name
import lookup_rdtype
from dns.rdataclass import *
from dns.rdatatype import *

# libraries that are available on Lambda
import re
import os
import sys
import boto3

# If you need to use a proxy server to access the Internet then hard code it 
# the details below, otherwise comment out or remove.
# os.environ["http_proxy"] = "10.10.10.10:3128"  # My on-premises proxy server
# os.environ["https_proxy"] = "10.10.10.10:3128"
# os.environ["no_proxy"] = "169.254.169.254"  # Don't proxy for meta-data service as Lambda  needs to get IAM credentials

# setup the boto3 client to talk to AWS APIs
route53 = boto3.client('route53')


# Function to create, update, delete records in Route 53
def update_resource_record(zone_id, host_name, domain, rectype, changerec, ttl, action, dry_run):
    if dry_run:
        dry_str = '(dry-run) '
    else:
        dry_str = ''

    if domain[-1] != '.':
        domain = domain + '.'

    if not (rectype == 'NS' and host_name == '@'):
        if host_name == '@':
            host_name = ''
        elif host_name[-1] != '.':
            host_name = host_name + '.'
        fqdn = host_name + domain

        dns_changes = {
            'Comment': 'Managed by Lambda Mirror DNS',
            'Changes': [
                {
                    'Action': action,
                    'ResourceRecordSet': {
                        'Name': fqdn,
                        'Type': rectype,
                        'ResourceRecords': [],
                        'TTL': ttl
                    }
                }
            ]
        }

        for value in changerec:  # Build the recordset
            dns_changes['Changes'][0]['ResourceRecordSet']['ResourceRecords'].append({'Value': str(value)})
            print '%s%s: %s %s => %s (ttl %d)' % (dry_str, action, rectype, fqdn, str(value), ttl)

        if not dry_run:
            route53.change_resource_record_sets(HostedZoneId=zone_id, ChangeBatch=dns_changes)

        return True

def adjust_node_name(origin1, origin2, name):
    if name == '@':
        fqdn = str(origin1)
    elif name.endswith('.'):
        fqdn = name
    else:
        fqdn = name + '.' + str(origin1)
    fqdn = fqdn.rstrip('.')
    name2 = re.sub('\.?' + re.escape(str(origin2).rstrip('.')) + '$', '', fqdn)
    if name2.endswith(str(origin1).rstrip('.')):
        raise InvalidNodeComparison('%s (%s) => (%s)' % (fqdn, origin1, origin2))
    if name2 == '':
        return '@'
    else:
        return name2

def check_record_target(target, name, origin):
    if name == '@':
        fqdn = '.' + str(origin)
    else:
        fqdn = name + '.' + str(origin)
    fqdn = fqdn.rstrip('.')
    target = target.rstrip('.')
    return fqdn.endswith('.' + target)

def convert_zone(domain, zone):
    new_zone = dns.zone.Zone(origin=(domain.rstrip('.') + '.'))
    for name in zone:
        new_name = adjust_node_name(zone.origin, domain, str(name))
        node = zone.get_node(name)
        for rdataset in node.rdatasets:
            new_rdataset = new_zone.find_rdataset(new_name, rdtype=rdataset.rdtype, create=True)
            for rdata in rdataset:
                new_rdata = dns.rdata.from_text(1, rdata.rdtype, rdata.to_text())

                if rdataset.rdtype == dns.rdatatype.CNAME:
                    new_rdata.target = dns.name.from_text(adjust_node_name(zone.origin, domain, str(new_rdata.target.derelativize(zone.origin))), origin=new_zone.origin)
                elif rdataset.rdtype == dns.rdatatype.MX:
                    new_rdata.exchange = dns.name.from_text(adjust_node_name(zone.origin, domain, str(new_rdata.exchange.derelativize(zone.origin))), origin=new_zone.origin)
                elif rdataset.rdtype == dns.rdatatype.NS:
                    new_rdata.target = dns.name.from_text(adjust_node_name(zone.origin, domain, str(new_rdata.target.derelativize(zone.origin))), origin=new_zone.origin)
                elif rdataset.rdtype == dns.rdatatype.SRV:
                    new_rdata.target = dns.name.from_text(adjust_node_name(zone.origin, domain, str(new_rdata.target.derelativize(zone.origin))), origin=new_zone.origin)

                new_rdataset.add(new_rdata, ttl=rdataset.ttl)
    return new_zone

# Perform a diff against the two zones and return difference set
def diff_zones(domain, zone1, zone2, ignore_ttl):
    differences = []
    for node in zone1: # Process existing
        if not check_record_target(domain, str(node), zone1.origin):
            continue

        node1 = zone1.get_node(node)
        node2 = zone2.get_node(node)
        if not node2:
            for record1 in node1:
                changerec = []
                for value1 in record1:
                    changerec.append(value1)
                change = (str(node), record1.rdtype, changerec, record1.ttl, 'DELETE')
                if change not in differences:
                    differences.append(change)
        else:
            for record1 in node1:
                record2 = node2.get_rdataset(record1.rdclass, record1.rdtype)
                if record1 != record2:  # update record to new zone
                    changerec = []
                    if record2:
                        action = 'UPSERT'
                        for value2 in record2:
                            changerec.append(value2)
                    else:
                        action = 'DELETE'
                        for value1 in record1:
                            changerec.append(value1)
                    change = (str(node), record1.rdtype, changerec, record1.ttl, action)
                    if change and change not in differences:
                        differences.append(change)

    for node in zone2:
        if not check_record_target(domain, str(node), zone2.origin):
            continue

        node1 = zone1.get_node(node)
        node2 = zone2.get_node(node)
        if node1:
            for record2 in node2:
                record1 = node1.get_rdataset(record2.rdclass, record2.rdtype)
                if record2.rdtype == dns.rdatatype.SOA:
                    continue
                elif not record1:  # Create new record
                    changerec = []
                    for value2 in record2:
                        changerec.append(value2)
                        change = (str(node), record2.rdtype, changerec, record2.ttl, 'UPSERT')
                        if change and change not in differences:
                            differences.append(change)
                elif record1 != record2:  # update record to new zone
                    changerec = []
                    for value2 in record2:
                        changerec.append(value2)

                    change = (str(node), record2.rdtype, changerec, record2.ttl, 'UPSERT')
                    if change and change not in differences:
                        differences.append(change)

                if record2.rdtype == dns.rdatatype.SOA or not record1:
                    continue
                elif not ignore_ttl and record2.ttl != record1.ttl:  # Check if the TTL has been updated
                    changerec = []
                    for value2 in record2:
                        changerec.append(value2)
                    change = (str(node), record2.rdtype, changerec, record2.ttl, 'UPSERT')
                    if change and change not in differences:
                        differences.append(change)
                elif record2.ttl != record1.ttl:
                    print 'Ignoring TTL update for %s' % node
        else:
            for record2 in node2:
                changerec = []
                for value2 in record2:
                    changerec.append(value2)
                    change = (str(node), record2.rdtype, changerec, record2.ttl, 'CREATE')
                    if change and change not in differences:
                        differences.append(change)

    return differences


# Main Handler for lambda function
def lambda_handler(event, context):
    # Setup configuration based on JSON formatted event data
    try:
        domain_name = event['Domain']
        master_ip = event['MasterDns']
        route53_zone_id = event['ZoneId']
        route53_zone_name = event['ZoneName']
        serial_record_name = event['SerialRecordName']
        if event['DryRun'] == 'True':
            dry_run = True
        else:
            dry_run = False
        if event['IgnoreTTL'] == 'True':
            ignore_ttl = True  # Ignore TTL changes in records
        else:
            ignore_ttl = False  # Update records even if the change is just the TTL
    except BaseException as e:
        print 'Error in setting up the environment, exiting now (%s) ' % e
        sys.exit('ERROR: check JSON file is complete:', event)

    # Transfer the master zone file from the DNS server via AXFR
    print 'Transferring zone %s from server %s ' % (domain_name, master_ip)
    master_zone = dns.zone.from_xfr(dns.query.xfr(master_ip, domain_name))

    # Read the zone from Route 53 via API and populate into zone object
    print 'Getting records from Route 53'
    vpc_zone = dns.zone.Zone(origin=route53_zone_name)
    vpc_recordset = route53.list_resource_record_sets(HostedZoneId=route53_zone_id)['ResourceRecordSets']
    for record in vpc_recordset:
        # Change the record name so that it doesn't have the domain name appended
        recordname = record['Name'].replace(route53_zone_name.rstrip('.') + '.', '')
        if recordname == '':
            recordname = "@"
        else:
            recordname = recordname.rstrip('.')
        rdataset = vpc_zone.find_rdataset(recordname, rdtype=str(record['Type']), create=True)
        for value in record['ResourceRecords']:
            rdata = dns.rdata.from_text(1, rdataset.rdtype, value['Value'])
            rdataset.add(rdata, ttl=int(record['TTL']))

    soa = master_zone.get_rdataset('@', 'SOA')
    serial = soa[0].serial  # What's the current zone version on-prem

    vpc_serial_txt = vpc_zone.get_rdataset(serial_record_name, 'TXT')
    if vpc_serial_txt:
        vpc_serial = int(vpc_serial_txt[0].to_text().lstrip('"').rstrip('"'))
    else:
        vpc_serial = None

    if vpc_serial and (vpc_serial > serial):
        sys.exit('ERROR: Route 53 VPC serial %s for domain %s is greater than existing serial %s' % (str(vpc_serial), domain_name, str(serial)))
    else:
        print 'Comparing SOA serial %s with %s ' % (vpc_serial, serial)
        master_zone_converted = convert_zone(route53_zone_name, master_zone)
        differences = diff_zones(domain_name, vpc_zone, master_zone_converted, ignore_ttl)

        for host, rdtype, record, ttl, action in differences:
            if rdtype != dns.rdatatype.SOA:
                update_resource_record(route53_zone_id, host, route53_zone_name, lookup_rdtype.recmap(rdtype), record, ttl, action, dry_run)

        # Update the VPC SOA to reflect the version just processed
        update_resource_record(route53_zone_id, serial_record_name, route53_zone_name, 'TXT', ['"%d"' % serial], 5, 'UPSERT', dry_run)

    return 'SUCCESS: %s mirrored to Route 53 VPC serial %s' % (domain_name, str(serial))

if __name__ == '__main__':
    lambda_handler({
        'Domain': 'ds.example.org.',
        'MasterDns': 'onpremises-ns.example.com',
        'ZoneId': 'XXX',
        'ZoneName': 'example.org.',
        'SerialRecordName': 'ds-dns-serial',
        'DryRun': 'True',
        'IgnoreTTL': 'False',
    }, None)
