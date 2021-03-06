#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift(@INC, './lib') }
BEGIN {
    use Test::Most;
    use_ok('Bio::MLST::SequenceType');
}

ok((my $sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3','recA-1'],
  non_matching_names => []
)), 'initialise ST');
is($sequence_type->sequence_type, 4, 'lookup the sequence type');
is($sequence_type->nearest_sequence_type,undef, 'lookup the nearest sequence type when exact match found');

# sequence type that doesnt exist in profile
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3','recA-200'],
  non_matching_names => [],
  report_lowest_st => 1
)), 'initialise sequence type that doesnt exist in profile');
is($sequence_type->sequence_type,undef, 'lookup the sequence type that doesnt exist in profile');
is($sequence_type->nearest_sequence_type,1, 'lookup the nearest sequence type for allele that doesnt exist in profile');

# missing an allele
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3'],
  non_matching_names => [],
  report_lowest_st => 1
)), 'initialise ST missing an allele');
is( $sequence_type->sequence_type, undef, 'lookup the sequence type missing an allele');
is($sequence_type->nearest_sequence_type, 1, 'lookup the nearest sequence type for missing an allele');

# underscore in allele header
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Streptococcus_pyogenes/profiles/spyogenes.txt',
  matching_names => ['gki-2','gtr-2','muri-1','muts-2','recp-2','xpt-2','yqil-2'],
  non_matching_names => []
)), 'initialise ST with underscore in allele header');
is( $sequence_type->sequence_type, 3, 'lookup the sequence type with underscore in allele header');
is($sequence_type->nearest_sequence_type, undef, 'lookup the nearest sequence type undescore in allele header');

# report closest match, not lowest ST
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2','purA-3'],
  non_matching_names => [],
  report_lowest_st => 0
)), 'initialise ST missing an allele');
is( $sequence_type->sequence_type, undef, 'lookup the sequence type missing an allele');
like($sequence_type->nearest_sequence_type, 'm/[14]/', 'lookup the nearest sequence type for missing an allele');

# Only partial matches
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => [],
  non_matching_names => ['adk-2~','purA-3~','recA-1~'],
  report_lowest_st => 0
)), 'initialise ST with imperfect alleles');
is( $sequence_type->sequence_type, undef, 'no perfect alleles, no perfect ST');
is($sequence_type->nearest_sequence_type, '4', 'no perfect alleles, imperfect ST');

# Mixture of perfect and imperfect matches
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2'],
  non_matching_names => ['purA-3~','recA-1~'],
  report_lowest_st => 0
)), 'initialise ST with mixture of alleles');
is( $sequence_type->sequence_type, undef, 'one perfect alleles, no perfect ST');
is($sequence_type->nearest_sequence_type, '4', 'one perfect alleles, imperfect ST');

# Multiple possible matches, some bad alelles
ok(($sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => ['adk-2'],
  non_matching_names => ['purA-3~'],
  report_lowest_st => 0
)), 'initialise ST with mixture of alleles and miss one');
is( $sequence_type->sequence_type, undef, 'one perfect, one partial, one missing');
is($sequence_type->nearest_sequence_type, '1', 'one perfect, one partial, one missing');

# check if two sequence types are similar
$sequence_type = Bio::MLST::SequenceType->new(
  profiles_filename => 't/data/databases/Escherichia_coli_1/profiles/escherichia_coli.txt',
  matching_names => [],
  non_matching_names => []
);
is($sequence_type->_allele_numbers_similar('1', '1'), 1, 'same alleles');
is($sequence_type->_allele_numbers_similar('1', '2'), 0, 'different alleles');
is($sequence_type->_allele_numbers_similar('1', '1~'), 1, 'similar alleles');
is($sequence_type->_allele_numbers_similar('1~', '1'), 1, 'other similar alleles');
is($sequence_type->_allele_numbers_similar('1~', '1~'), 1, 'other same alleles');
is($sequence_type->_allele_numbers_similar('1', '2~'), 0, 'more different alleles');

done_testing();
