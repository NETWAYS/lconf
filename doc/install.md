# LConf Installation

Please refer to https://www.netways.org/projects/lconf/wiki for detailed instructions.


# Release Checklist

Create support branch

    git checkout master
    git checkout -b support/1.4

Look for old version info

    grep -r '$oldversion' *

Edit version info

    vim m4/version.m4
    vim LConf.spec

Regenerate configure

    autoconf

Add a git tag

    git tag v1.4.0

Create release tarball

    VERSION=1.4.0
    git archive --format=tar --prefix=LConf-$VERSION/ tags/v$VERSION | gzip >LConf-$VERSION.tar.gz

Push origin

    git push origin support/1.4
    git push --tags

Merge master, next.


