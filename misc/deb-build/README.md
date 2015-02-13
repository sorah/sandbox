### Import key of repository

```
(▰╹◡╹) gpg --keyserver ... --recv-keys ...
```

### VM

make sure the key has imported

```
$ vagrant up
$ ./setup.sh
```

### Creating package

#### Import existing dsc

https://launchpad.net/ubuntu/+source/ruby-defaults/1:2.1.0.1ubuntu1

```
$ wget -P /tmp https://launchpad.net/ubuntu/+archive/primary/+files/ruby-defaults_2.1.0.1ubuntu1.tar.xz
$ wget -P /tmp https://launchpad.net/ubuntu/+archive/primary/+files/ruby-defaults_2.1.0.1ubuntu1.dsc
```

```
$ mkdir ruby-defaults
$ cd ruby-defaults
$ git init
```

```
$ gbp import-dsc /tmp/ruby-defaults_2.1.0.1ubuntu1.dsc
gbp:info: Tag debian/2.1.0.1ubuntu1 not found, importing Debian tarball
gbp:info: Version '1:2.1.0.1ubuntu1' imported under 'ruby-defaults'
```

#### From scratch, upstream is git repository

```
$ git clone https://github.com/tools/godep
$ cd godep
$ git checkout -m master upstream
$ git checkout -b master upstream
$ git remote rename origin upstream
$ git remote add origin ...
$ git tag upstream/VERSION
$ dh_make --createorig
```

VERSION should be upstream package version, if upstream doesn't do versioning, use date in format YYYYMMDD

### Building packages

#### No upstream

```
# dev
$ gbp buildpackage --git-pristine-tar --git-pristine-tar-commit --git-ignore-new

# release
$ gbp buildpackage --git-pristine-tar --git-pristine-tar-commit --git-tag
$ git push && git push --tags
```

#### Upstream is Git, without using tarball

```
# dev
$ gbp buildpackage --git-pristine-tar --git-pristine-tar-commit --git-upstream-tag=UPSTREAM_TAG --git-ignore-new

# release
$ gbp buildpackage --git-pristine-tar --git-pristine-tar-commit --git-upstream-tag=UPSTREAM_TAG --git-tag
$ git push && git push --tags
```

#### Upstream is tarball

```
$ gbp import-orig -u 1.4.1 ../golang_1.4.1.orig.tar.gz

# dev
$ gbp buildpackage --git-pristine-tar --git-debian-branch=master --git-upstream-branch=upstream --git-ignore-new

# release
$ gbp buildpackage --git-pristine-tar --git-debian-branch=master --git-upstream-branch=upstream --git-tag
$ git push && git push --tags
```


### Publishing packages

```
vagrant $ git push --all origin
vagrant $ git push --tags origin

vagrant $ cd ..

vagrant $ deb-release path/to.changes
```

### .gitignore

```
# debian/.gitignore

<package name>/
*.log
*.substvars
files
```

#### Version

`dpkg --compare-version A op B` may help you (`dpkg --compare-version '1:2.1.0ubuntu1' '<' '1:2.1.5foo1' && echo true`)
