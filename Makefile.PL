
use strict;
use warnings;

 BEGIN { require 5.006; } 

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Test::MinimumVersion',
                       'DISTNAME' => 'Test-MinimumVersion',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Ricardo Signes',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0',
                                             'Test::Tester' => '0'
                                           },
                       'ABSTRACT' => 'does your code require newer perl than you think?',
                       'EXE_FILES' => [],
                       'VERSION' => '0.101050',
                       'PREREQ_PM' => {
                                        'File::Find::Rule' => '0',
                                        'YAML::Tiny' => '1.40',
                                        'version' => '0.70',
                                        'File::Find::Rule::Perl' => '0',
                                        'Exporter' => '0',
                                        'Perl::MinimumVersion' => '1.20',
                                        'Test::Builder' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



