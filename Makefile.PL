#!/usr/bin/perl

use inc::Module::Install;
use 5.008;

name		('PerlIO-via-dynamic');
author		('Chia-liang Kao <clkao@clkao.org>');
abstract_from	('dynamic.pm');
license		('perl');
version_from	('dynamic.pm');

include('ExtUtils::AutoInstall');
auto_install();

WriteAll( sign => 1 );
