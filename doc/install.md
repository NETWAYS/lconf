# LConf Installation

Please refer to https://www.netways.org/projects/lconf/wiki for detailed instructions.


# Release Checklist

Create support branch

    git checkout master
    git checkout -b support/1.5

Look for old version info

    grep -r '$oldversion' *

Edit version info

    vim m4/version.m4
    vim LConf.spec

Regenerate configure

    autoconf

Commit the release

    git commit -v -m "Release <VERSION>"

Add a git tag

MF:

    git tag -u D14A1F16 -m "Version <VERSION>" v<VERSION>

Create release tarball

    VERSION=1.5.0
    git archive --format=tar --prefix=LConf-$VERSION/ tags/v$VERSION | gzip >LConf-$VERSION.tar.gz
    md5sum LConf-$VERSION.tar.gz > LConf-$VERSION.tar.gz.md5

Push origin

    git push origin support/1.5
    git push --tags

Merge master, next.


