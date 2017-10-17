#!./perl

use utf8;

# This tests that the ANYOF nodes generated by bracketed character classes are
# as expected.  The representation of these is not guaranteed, and this test
# may need to be updated if it changes.  But it is here to make sure that no
# unexpected changes occur.  These could come from faulty generation of the
# node, or faulty display of them (or both).  Because these causes come from
# very different parts of the regex compiler, it is unlikely that a commit
# would change both of them, so this test will adequately serve to test both.

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib','.','../ext/re');
    require Config; import Config;
    skip_all('no re module') unless defined &DynaLoader::boot_DynaLoader;
}

# An array is used instead of a hash, so that the tests are carried out in the
# order given by this file.  Even-numbered indices are the regexes to compile.
# The next higher element is the expected compilation result.
#
# It is painful to port some of these to EBCDIC, as not only do the code point
# numbers change (for those < 256), but the order changes, as the compiled
# version is sorted by native code point order.  On EBCDIC, \r comes before
# \n, and 'k' before "K', for example.  So, the tests where there are
# differences are skipped on EBCDIC.  They are all at the beginning of the
# array, and a special marker entry is used to delmit the boundary between
# skipped and not skipped.

my @tests = (
    '[[{]' => 'ANYOF[\[\{]',
    '[^\S ]' => 'ANYOFD[\t\n\x0B\f\r{utf8}\x85\xA0][1680 2000-200A 2028-2029 202F 205F 3000]',
    '[^\n\r]' => 'ANYOF[^\n\r][0100-INFINITY]',
    '[^\/\|,\$\%%\@\ \%"\<\>\:\#\&\*\{\}\[\]\(\)]' => 'ANYOF[^ "#$%&()*,/:<>@\[\]\{|\}][0100-INFINITY]',
    '[^[:^print:][:^ascii:]]' => 'ANYOF[\x20-\x7E]',
    '[ [:blank:]]' => 'ANYOFD[\t {utf8}\xA0][1680 2000-200A 202F 205F 3000]',
    '[_[:^blank:]]' => 'ANYOFD[^\t {utf8}\xA0][0100-167F 1681-1FFF 200B-202E 2030-205E 2060-2FFF 3001-INFINITY]',
    '[\xA0[:^blank:]]' => 'ANYOF[^\t ][0100-167F 1681-1FFF 200B-202E 2030-205E 2060-2FFF 3001-INFINITY]',
    '[ [:blank:]]' => 'ANYOFD[\t {utf8}\xA0][1680 2000-200A 202F 205F 3000]',
    '[_[:^blank:]]' => 'ANYOFD[^\t {utf8}\xA0][0100-167F 1681-1FFF 200B-202E 2030-205E 2060-2FFF 3001-INFINITY]',
    '[\xA0[:^blank:]]' => 'ANYOF[^\t ][0100-167F 1681-1FFF 200B-202E 2030-205E 2060-2FFF 3001-INFINITY]',
    '(?d:[_[:^blank:]])' => 'ANYOFD[^\t {utf8}\xA0][0100-167F 1681-1FFF 200B-202E 2030-205E 2060-2FFF 3001-INFINITY]',
    '[\x{07}-\x{0B}]' => 'ANYOF[\a\b\t\n\x0B]',
    '(?il:[\x{212A}])' => 'ANYOFL{i}[{utf8 locale}Kk][212A]',
    '(?il:(?[\x{212A}]))' => 'ANYOFL{utf8-locale-reqd}[Kk][212A]',

    'ebcdic_ok_below_this_marker',

    '(?l:[\x{212A}])' => 'ANYOFL[212A]',
    '(?l:[\s\x{212A}])' => 'ANYOFL[\s][1680 2000-200A 2028-2029 202F 205F 212A 3000]',
    '(?l:[^\S\x{202F}])' => 'ANYOFL[^\\S][1680 2000-200A 2028-2029 205F 3000]',
    '(?i:[^:])' => 'ANYOF[^:][0100-INFINITY]',
    '[\p{Any}]' => 'ANYOF[\x00-\xFF][0100-10FFFF]',
    '[\p{IsMyRuntimeProperty}]' => 'ANYOF[+utf8::IsMyRuntimeProperty]',
    '[^\p{IsMyRuntimeProperty}]' => 'ANYOF[^{+utf8::IsMyRuntimeProperty}]',
    '[a\p{IsMyRuntimeProperty}]' => 'ANYOF[a][+utf8::IsMyRuntimeProperty]',
    '[^a\p{IsMyRuntimeProperty}]' => 'ANYOF[^a{+utf8::IsMyRuntimeProperty}]',
    '[^a\x{100}\p{IsMyRuntimeProperty}]' => 'ANYOF[^a{+utf8::IsMyRuntimeProperty}0100]',
    '[{INFINITY_minus_1}]' => 'ANYOF[INFINITY_minus_1]',
    '[{INFINITY}]' => 'ANYOF[INFINITY-INFINITY]',
    '[\x{102}\x{104}]' => 'ANYOF[0102 0104]',
    '[\x{104}\x{102}]' => 'ANYOF[0102 0104]',
    '[\x{103}\x{102}]' => 'ANYOF[0102-0103]',
    '[\x{00}-{INFINITY_minus_1}]' => 'ANYOF[\x00-\xFF][0100-INFINITY_minus_1]',
    '[\x{00}-{INFINITY}]' => 'SANY',
    '[\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY_minus_1]',
    '[\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{104}\x{102}\x{103}]' => 'ANYOF[0102-0104]',
    '[\x{102}-\x{104}\x{101}]' => 'ANYOF[0101-0104]',
    '[\x{102}-\x{104}\x{102}]' => 'ANYOF[0102-0104]',
    '[\x{102}-\x{104}\x{103}]' => 'ANYOF[0102-0104]',
    '[\x{102}-\x{104}\x{104}]' => 'ANYOF[0102-0104]',
    '[\x{102}-\x{104}\x{105}]' => 'ANYOF[0102-0105]',
    '[\x{102}-\x{104}\x{106}]' => 'ANYOF[0102-0104 0106]',
    '[\x{102}-\x{104}{INFINITY_minus_1}]' => 'ANYOF[0102-0104 INFINITY_minus_1]',
    '[\x{102}-\x{104}{INFINITY}]' => 'ANYOF[0102-0104 INFINITY-INFINITY]',
    '[\x{102}-\x{104}\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{102}-\x{104}\x{102}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{102}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{103}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{103}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{104}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{104}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{105}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{105}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{106}-{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0106-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{106}-{INFINITY}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}]' => 'ANYOF[0101-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}]' => 'ANYOF[0102-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}]' => 'ANYOF[0102-0104 0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{107}]' => 'ANYOF[0102-0104 0107-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{108}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{109}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{10A}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{10B}]' => 'ANYOF[0102-0104 0108-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0108-010A INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}{INFINITY}]' => 'ANYOF[0102-0104 0108-010A INFINITY-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{102}]' => 'ANYOF[0101-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{103}]' => 'ANYOF[0101-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{104}]' => 'ANYOF[0101-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{105}]' => 'ANYOF[0101-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{106}]' => 'ANYOF[0101-0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{107}]' => 'ANYOF[0101-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{108}]' => 'ANYOF[0101-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{109}]' => 'ANYOF[0101-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{10A}]' => 'ANYOF[0101-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{10B}]' => 'ANYOF[0101-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{102}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{103}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{104}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{105}]' => 'ANYOF[0102-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{106}]' => 'ANYOF[0102-0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{107}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{108}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{109}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10A}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10B}]' => 'ANYOF[0102-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10C}]' => 'ANYOF[0102-010C]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{102}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{104}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{105}]' => 'ANYOF[0102-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{106}]' => 'ANYOF[0102-0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{107}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{108}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{109}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10A}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10B}]' => 'ANYOF[0102-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10C}]' => 'ANYOF[0102-010C]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{103}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}]' => 'ANYOF[0102-0104 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{105}]' => 'ANYOF[0102-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{106}]' => 'ANYOF[0102-0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{107}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{108}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{109}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10A}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10B}]' => 'ANYOF[0102-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10C}]' => 'ANYOF[0102-010C]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{104}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}]' => 'ANYOF[0102-0105 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{106}]' => 'ANYOF[0102-0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{107}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{108}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{109}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10A}]' => 'ANYOF[0102-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10B}]' => 'ANYOF[0102-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10C}]' => 'ANYOF[0102-010C]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{105}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}]' => 'ANYOF[0102-0104 0106 0108-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{107}]' => 'ANYOF[0102-0104 0106-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{108}]' => 'ANYOF[0102-0104 0106-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{109}]' => 'ANYOF[0102-0104 0106-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10A}]' => 'ANYOF[0102-0104 0106-010A]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10B}]' => 'ANYOF[0102-0104 0106-010B]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10C}]' => 'ANYOF[0102-0104 0106-010C]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0106-INFINITY_minus_1]',
    '[\x{102}-\x{104}\x{108}-\x{10A}\x{106}-{INFINITY}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}{INFINITY_minus_1}]' => 'ANYOF[010C-INFINITY]',
    '[\x{10C}-{INFINITY}{INFINITY}]' => 'ANYOF[010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}\x{104}]' => 'ANYOF[0102 0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{104}\x{102}]' => 'ANYOF[0102 0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{103}\x{102}]' => 'ANYOF[0102-0103 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{00}-{INFINITY_minus_1}]' => 'SANY',
    '[\x{10C}-{INFINITY}\x{00}-{INFINITY}]' => 'SANY',
    '[\x{10C}-{INFINITY}\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{104}\x{102}\x{103}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{101}]' => 'ANYOF[0101-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{102}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{103}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{104}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{105}]' => 'ANYOF[0102-0105 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{106}]' => 'ANYOF[0102-0104 0106 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}{INFINITY_minus_1}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}{INFINITY}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{102}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{102}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{103}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{103}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{104}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{104}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{105}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{105}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{106}-{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{106}-{INFINITY}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}]' => 'ANYOF[0101-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}]' => 'ANYOF[0102-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}]' => 'ANYOF[0102-0104 0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{107}]' => 'ANYOF[0102-0104 0107-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{108}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{109}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{10A}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{10B}]' => 'ANYOF[0102-0104 0108-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}{INFINITY}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{102}]' => 'ANYOF[0101-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{103}]' => 'ANYOF[0101-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{104}]' => 'ANYOF[0101-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{105}]' => 'ANYOF[0101-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{106}]' => 'ANYOF[0101-0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{107}]' => 'ANYOF[0101-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{108}]' => 'ANYOF[0101-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{109}]' => 'ANYOF[0101-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{10A}]' => 'ANYOF[0101-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-\x{10B}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-{INFINITY_minus_1}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{101}-{INFINITY}]' => 'ANYOF[0101-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{102}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{103}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{104}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{105}]' => 'ANYOF[0102-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{106}]' => 'ANYOF[0102-0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{107}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{108}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{109}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10A}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10B}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-\x{10C}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{102}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{104}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{105}]' => 'ANYOF[0102-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{106}]' => 'ANYOF[0102-0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{107}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{108}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{109}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10A}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10B}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-\x{10C}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{103}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}]' => 'ANYOF[0102-0104 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{105}]' => 'ANYOF[0102-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{106}]' => 'ANYOF[0102-0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{107}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{108}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{109}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10A}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10B}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-\x{10C}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{104}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}]' => 'ANYOF[0102-0105 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{106}]' => 'ANYOF[0102-0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{107}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{108}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{109}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10A}]' => 'ANYOF[0102-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10B}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-\x{10C}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-{INFINITY_minus_1}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{105}-{INFINITY}]' => 'ANYOF[0102-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}]' => 'ANYOF[0102-0104 0106 0108-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{107}]' => 'ANYOF[0102-0104 0106-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{108}]' => 'ANYOF[0102-0104 0106-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{109}]' => 'ANYOF[0102-0104 0106-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10A}]' => 'ANYOF[0102-0104 0106-010A 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10B}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-\x{10C}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-{INFINITY_minus_1}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{108}-\x{10A}\x{106}-{INFINITY}]' => 'ANYOF[0102-0104 0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}]' => 'ANYOF[0104 0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{105}]' => 'ANYOF[0105-INFINITY]',
    '[\x{106}-{INFINITY}\x{106}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{107}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}-\x{105}]' => 'ANYOF[0104-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}-\x{106}]' => 'ANYOF[0104-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}-\x{107}]' => 'ANYOF[0104-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}-{INFINITY_minus_1}]' => 'ANYOF[0104-INFINITY]',
    '[\x{106}-{INFINITY}\x{104}-{INFINITY}]' => 'ANYOF[0104-INFINITY]',
    '[\x{106}-{INFINITY}\x{105}-\x{106}]' => 'ANYOF[0105-INFINITY]',
    '[\x{106}-{INFINITY}\x{105}-\x{107}]' => 'ANYOF[0105-INFINITY]',
    '[\x{106}-{INFINITY}\x{105}-{INFINITY_minus_1}]' => 'ANYOF[0105-INFINITY]',
    '[\x{106}-{INFINITY}\x{105}-{INFINITY}]' => 'ANYOF[0105-INFINITY]',
    '[\x{106}-{INFINITY}\x{106}-\x{107}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{106}-{INFINITY_minus_1}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{106}-{INFINITY}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{107}-\x{107}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{107}-{INFINITY_minus_1}]' => 'ANYOF[0106-INFINITY]',
    '[\x{106}-{INFINITY}\x{107}-{INFINITY}]' => 'ANYOF[0106-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{100}]' => 'ANYOF[0100 0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{101}]' => 'ANYOF[0101-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{102}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{103}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{104}]' => 'ANYOF[0102-0104 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{105}]' => 'ANYOF[0102-0105 010C-INFINITY]',
    '[\x{10C}-{INFINITY}\x{102}-\x{104}\x{106}]' => 'ANYOF[0102-0104 0106 010C-INFINITY]',
);

# 2**32-1 or 2**64-1
my $highest_cp_string = "F" x (($Config{uvsize} < 8) ? 8 : 16);

my $next_highest_cp_string = $highest_cp_string =~ s/ F $ /E/xr;

my $highest_cp = "\\x{$highest_cp_string}";
my $next_highest_cp = "\\x{$next_highest_cp_string}";

plan(scalar (@tests - 1) / 2);  # -1 because of the marker.

my $skip_ebcdic = $::IS_EBCDIC;
while (defined (my $test = shift @tests)) {

    if ($test eq 'ebcdic_ok_below_this_marker') {
        $skip_ebcdic = 0;
        next;
    }

    my $expected = shift @tests;

    SKIP: {
        skip("test not ported to EBCDIC", 1) if $skip_ebcdic;

        my $display_expected = $expected
                                  =~ s/ INFINITY_minus_1 /$next_highest_cp/xgr;

        # Convert platform-independent values to what is suitable for the
        # platform
        $test =~ s/\{INFINITY\}/$highest_cp/g;
        $test =~ s/\{INFINITY_minus_1\}/$next_highest_cp/g;

        $test = "qr/$test/";
        my $actual_test = "use re qw(Debug COMPILE); $test";

        my $result = fresh_perl($actual_test);
        if ($? != 0) {  # Re-run so as to display STDERR.
            fail($test);
            fresh_perl($actual_test, { stderr => 0, verbose => 1 });
            next;
        }

        # The Debug output will come back as a bunch of lines.  We are
        # interested only in the line after /Final program/
        my @lines = split /\n/, $result;
        while (defined ($_ = shift @lines)) {
            next unless /Final program/;
            $_ = shift @lines;

            s/ \s* \( \d+ \) \s* //x;   # Get rid of the node branch
            s/ ^ \s* \d+ : \s* //x;     # ... And the node number

            # Use platform-independent values
            s/$highest_cp_string/INFINITY/g;
            s/$next_highest_cp_string/INFINITY_minus_1/g;

            is($_, $expected,
               "Verify compilation of $test displays as $display_expected");
            last;   # Discard the rest of this test's output
        }
    }
}
