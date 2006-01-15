use inc::Module::Install;

name           'PITA';
all_from       'lib/PITA.pm';
requires       'Carp'             => 0;
requires       'version'          => '0.50';
requires       'File::Spec'       => '0.80';
requires       'File::Copy'       => 0;
requires       'File::Basename'   => 0;
requires       'File::Remove'     => '0.22';
requires       'Params::Util'     => '0.10';
requires       'File::Find::Rule' => 0;
requires       'Archive::Extract' => '0.07';
requires       'URI'              => 0;
requires       'HTTP::Daemon'     => 0;
requires       'LWP'              => '5.69';
requires       'Process'          => '0.10';
# requires       'Process::YAML'    => '0.01';
requires       'PITA::XML'        => '0.12';
requires       'PITA::Scheme'     => '0.11';
build_requires 'Test::More'       => '0.47';

auto_install;
WriteAll;
