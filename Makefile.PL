use inc::Module::Install;

name     'Catalyst-Engine-SCGI-PreFork';
all_from 'lib/Catalyst/Engine/SCGI/PreFork.pm';
author   'Orlando Vazquez <orlandov@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

