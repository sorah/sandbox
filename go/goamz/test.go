package main

import (
	"fmt"
	"github.com/crowdmob/goamz/route53"
	"github.com/crowdmob/goamz/aws"
)

func main() {
	auth, _ := aws.EnvAuth()
	r53, _ := route53.NewRoute53(auth)

	res, _ := r53.GetHostedZone(os.Args[0])
	fmt.Printf("%#v\n", res)
	
	res, _ = r53.ListHostedZones()
	fmt.Printf("%#v\n", res)
}
