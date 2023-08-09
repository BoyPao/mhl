# MHL
mhl: Match highlight.
mhl is a Vim plugin to let match more convenient.
Match pattern will be highlighted with some colors.
The basic idea has refered to
Yuheng Xie's Mark.vim (https://github.com/vim-scripts/Mark).
To reslove highlight priority problem, mhl use matchadd() rather then
syntax match.

License: GPL-3.0-or-later
Copyright (c) 2023 Peng Hao <635945005@qq.com>

# Features
- Highlight match words with colors

# Installation
- Install manually
```
git clone --depth=1 https://github.com/BoyPao/mhl.git
cp mhl.vim ~/.vim/plugin
```
- Install by vim-plug (recommanded)
```
Plug 'BoyPao/mhl'
```
