#!/usr/bin/perl
use strict;
use warnings;

my $file = shift @ARGV or die "usage: $0 <SlackBuild>\n";

open(my $fh, "<", $file) or die "open($file): $!\n";
my @lines = <$fh>;
close($fh);

my $orig = join('', @lines);

sub append_token {
    my ($val, $token) = @_;
    return $val if $val =~ /\Q$token\E/;
    $val =~ s/\s*\z//;
    return $val . " " . $token;
}

my $re_slkc  = qr/\$(?:\{)?SLKCFLAGS(?:\})?/;
my $re_slkld = qr/\$(?:\{)?SLKLDFLAGS(?:\})?/;
my $re_ld    = qr/\$(?:\{)?LDFLAGS/;

for my $ln (@lines) {
    # Do not touch pure comments
    next if $ln =~ /^\s*#/;

    # export CFLAGS/CXXFLAGS="...SLKCFLAGS..."
    $ln =~ s{
        ^(\s*export\s+(CFLAGS|CXXFLAGS)\s*=\s*")([^"\n]*$re_slkc[^"\n]*)"
    }{
        my ($pfx, $var, $val) = ($1, $2, $3);
        $val = append_token($val, '$HARDEN_CFLAGS');
        qq{$pfx$val"}
    }ex;

    # Any CFLAGS/CXXFLAGS="...SLKCFLAGS..." anywhere on the line (e.g. make ... CFLAGS="...")
    $ln =~ s{
        (\b(CFLAGS|CXXFLAGS)\s*=\s*")([^"\n]*$re_slkc[^"\n]*)"
    }{
        my ($pfx, $var, $val) = ($1, $2, $3);
        $val = append_token($val, '$HARDEN_CFLAGS');
        qq{$pfx$val"}
    }gex;

    # cmake args: -DCMAKE_C_FLAGS...="...SLKCFLAGS..."
    $ln =~ s{
        (-DCMAKE_(?:C|CXX)_FLAGS[^=\s]*=)"([^"\n]*$re_slkc[^"\n]*)"
    }{
        my ($arg, $val) = ($1, $2);
        $val = append_token($val, '$HARDEN_CFLAGS');
        qq{$arg"$val"}
    }gex;

    # export LDFLAGS="..." (preserve existing LDFLAGS if SlackBuild resets it)
    $ln =~ s{
        ^(\s*export\s+LDFLAGS\s*=\s*")([^"\n]*)"
    }{
        my ($pfx, $val) = ($1, $2);
        if ($val =~ /$re_ld/) {
            qq{$pfx$val"}
        } else {
            qq{$pfx\${LDFLAGS:-} $val"}
        }
    }ex;

    # inline env: LDFLAGS="$SLKLDFLAGS ..." -> LDFLAGS="${LDFLAGS:-} $SLKLDFLAGS ..."
    if ($ln =~ /\bLDFLAGS\s*=\s*".*$re_slkld/ && $ln !~ /$re_ld/) {
        $ln =~ s/$re_slkld/\${LDFLAGS:-} \$SLKLDFLAGS/;
    }
}

my $new = join('', @lines);
if ($new ne $orig) {
    open(my $out, ">", $file) or die "write($file): $!\n";
    print $out $new;
    close($out);
}
exit 0;
