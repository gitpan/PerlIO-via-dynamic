#!/usr/bin/perl
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR		=> 'Chia-liang Kao (clkao@clkao.org)',
    ABSTRACT		=> 'Dynamic PerlIO layers',
    NAME		=> 'PerlIO::via::dynamic',
    VERSION_FROM	=> 'dynamic.pm',
    DISTNAME		=> 'PerlIO-via-dynamic',

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

