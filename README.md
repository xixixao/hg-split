# hg-split

Takes a list of files and puts changes made to them in this commit into a separate sibling commit. Uses `hg amend` to automatically rebase the children of the original commit.

See [hg-split-interactive](http://github.com/xixixao/hg-split-interactive) for a demo.

Install:
```bash
npm install -g xixixao/hg-split
```

Run:
```bash
hg-split -b new-bookmark-name -m \"New commit message\" -- foo.txt bar.txt"
```

Show help:
```bash
hg-split --help
```

## Requirements

`hg amend` installed, see [hg-experimental](https://bitbucket.org/facebook/hg-experimental/) for instructions.
