#!/usr/bin/env perl

# This file is part of IREX tools.

# Please refer "Copyright file" at the root directory.
# (C) IREX committee IREX�¹԰Ѱ���. All rights reserved.  

# -----------------------------------------------------------------------------
# NE������������ե�����(goldenfile)�Ȳ����ե�����(systemfile)�Ȥ����
# �ƥɥ�����Ȥ��Ȥ˥�����(*.scr)����ݡ���(*.rep)��ɽ�������ե���������
# -----------------------------------------------------------------------------
package NESCR;
# use I18N::Japanese;
use strict;

($#ARGV == 1) || die "Usage : $0 [goldenfile] [systemfile]\n";

# -----------------------------------------------------------------------------
# �����Х��ѿ�
# -----------------------------------------------------------------------------
# �������ޥ���
my $inputfile_suffix = '.idx';
my $scorefile_suffix = '.scr';
my $reportfile_suffix = '.rep';
my $tag = 'TAGSET';
my $doc = 'DOCNO';
my $optional_tag = 'OPTIONAL';
my $ind = '\@';
my $comment = '\#';
my @exclude_docnum = (100000067);
#my @exclude_docnum = ();

# ���ϥե�����
my $goldenfile = shift(@ARGV);
my $systemfile = shift(@ARGV);

# ���ϥե�����
my $scrfile;
my $repfile;
($scrfile = $systemfile) =~ s/$inputfile_suffix/$scorefile_suffix/;
if ($scrfile eq $systemfile) {
    die "Use the suffix \"$inputfile_suffix\" for the input file.\n";
}
($repfile = $systemfile) =~ s/$inputfile_suffix/$reportfile_suffix/;

# ����
my $golden = NESCR->bless_ref;
my $system = NESCR->bless_ref;
my $eval = NESCR->bless_ref;
my $item = NESCR->bless_ref;
my $order;			# Document, TAGSET �ν��Ͻ������¸

# -----------------------------------------------------------------------------
# �ᥤ��ץ����
# -----------------------------------------------------------------------------
#-----------------------#
# goldenfile ���ɤ߹��� #
#-----------------------#
$order = $golden->read_file($goldenfile);

#-----------------------#
# systemfile ���ɤ߹��� #
#-----------------------#
$system->read_file($systemfile);

#---------------------------------#
# goldenfile �� systemfile ����� #
#---------------------------------#
foreach (keys %$golden) {
    my $docnum = $_;

    # ���򥿥������������ꤵ�줿��(cor)����äƿ��ꤵ�줿��(mis)��Ĵ�٤� #
    foreach (keys %{$golden->{$docnum}}) {
	my $offset_gld = $_;
	unless (defined($golden->{$docnum}{$offset_gld})) {
	    next;
	}
	my ($gld_tag, $gld_body) 
	    = split(/$;/, $golden->{$docnum}{$offset_gld});
	my ($offset_gld_start, $offset_gld_end) = split(/$;/, $offset_gld);

	if ($gld_tag eq $optional_tag) {
	    # OPTIONAL tag �ΤȤ� #
	    foreach (keys %{$system->{$docnum}}) {
		my $offset_sys = $_;
		if (defined($system->{$docnum}{$offset_sys})) {
		    my ($sys_tag, $sys_body) 
			= split(/$;/, $system->{$docnum}{$offset_sys});
		    my ($offset_sys_start, $offset_sys_end) 
			= split(/$;/, $offset_sys);

		    # OPTIONAL tag ���ϰ���Τ�Τ�ɾ���оݳ��Ȥ��� #
		    if ($offset_sys_start >= $offset_gld_start 
			&& $offset_sys_end <= $offset_gld_end) {
			my $rep = sprintf(" opt-s  %6d %6d   %-15s %s\n", 
					  $offset_sys_start, $offset_sys_end, 
					  $sys_tag, $sys_body);
			push(@{$item->{$docnum}{$offset_sys_start}}, $rep);
			undef($system->{$docnum}{$offset_sys});
		    }
		}
	    }
	    my $rep = sprintf(" opt-a  %6d %6d   %-15s %s\n", 
			      $offset_gld_start, $offset_gld_end, 
			      $gld_tag, $gld_body);
	    push(@{$item->{$docnum}{$offset_gld_start}}, $rep);
	    undef($golden->{$docnum}{$offset_gld});
	    $eval->{$gld_tag}{'ALL'}{'OPT'}++;
	    $eval->{$gld_tag}{$docnum}{'OPT'}++;
	} else {
	    # OPTIONAL tag �ʳ��ΤȤ� #
	    if (defined($system->{$docnum}{$offset_gld})) {
		my ($sys_tag, $sys_body) 
		    = split(/$;/, $system->{$docnum}{$offset_gld});
		if ($gld_tag eq $sys_tag) {
		    $eval->{$gld_tag}{'ALL'}{'COR'}++;
		    $eval->{$gld_tag}{$docnum}{'COR'}++;
		    my $rep = sprintf(" cor    %6d %6d   %-15s %s\n", 
				      $offset_gld_start, $offset_gld_end, 
				      $gld_tag, $gld_body);
		    push(@{$item->{$docnum}{$offset_gld_start}}, $rep);
		} else {
		    my $rep = sprintf(" mis    %6d %6d   %-15s %s\n", 
				      $offset_gld_start, $offset_gld_end, 
				      $gld_tag, $gld_body);
		    push(@{$item->{$docnum}{$offset_gld_start}}, $rep);
		}
	    } else {
		my $rep = sprintf(" mis    %6d %6d   %-15s %s\n", 
				  $offset_gld_start, $offset_gld_end, 
				  $gld_tag, $gld_body);
		push(@{$item->{$docnum}{$offset_gld_start}}, $rep);
	    }
	    $eval->{$gld_tag}{'ALL'}{'GLD'}++;
	    $eval->{$gld_tag}{$docnum}{'GLD'}++;
	}
    }

    # �����ƥब��äƿ��ꤷ��(ovg)������Ĵ�٤� #
    foreach (keys %{$system->{$docnum}}) {
	my $offset_sys = $_;
	if (defined($system->{$docnum}{$offset_sys})) {
	    my ($sys_tag, $sys_body) 
		= split(/$;/, $system->{$docnum}{$offset_sys});
	    my ($offset_sys_start, $offset_sys_end) = split(/$;/, $offset_sys);
	    $eval->{$sys_tag}{'ALL'}{'SYS'}++;
	    $eval->{$sys_tag}{$docnum}{'SYS'}++;
	    if (defined($golden->{$docnum}{$offset_sys})) {
		my ($gld_tag, $gld_body) 
		    = split(/$;/, $golden->{$docnum}{$offset_sys});
		if ($gld_tag ne $sys_tag) {
		    my $rep = sprintf(" ovg    %6d %6d   %-15s %s\n", 
				      $offset_sys_start, $offset_sys_end, 
				      $sys_tag, $sys_body);
		    push(@{$item->{$docnum}{$offset_sys_start}}, $rep);
		}
	    } else {
		my $rep = sprintf(" ovg    %6d %6d   %-15s %s\n", 
				  $offset_sys_start, $offset_sys_end, 
				  $sys_tag, $sys_body);
		push(@{$item->{$docnum}{$offset_sys_start}}, $rep);
	    }
	}
    }
}

#------------------#
# ɾ���ȷ�̤�ɽ�� #
#------------------#
open(SCR, ">".$scrfile) || die "Can't open $scrfile: $!\n";
open(REP, ">".$repfile) || die "Can't open $repfile: $!\n";

push(@{$order->{$doc}}, 'ALL');
my $document;
foreach $document (@{$order->{$doc}}) {
    #--------------------#
    # scorefile �ؤν��� #
    #--------------------#
    my ($all_gld, $all_sys, $all_cor, $all_mis, $all_ovg);
    my ($all_rec, $all_pre, $f);

    # Document number������������̾��ɽ�� #
    if ($document eq 'ALL') {
	print SCR " * * * SUMMARY SCORES * * *\n";
    } else {
	print SCR "Document: $document\n";
    }
    print SCR "-----------------------------+";
    print SCR "--------+-------------+---------------\n";
    printf SCR "%14s %6s %6s | %6s | %5s %5s | %6s %6s\n", 
    ' ', 'GLD', 'SYS', 'COR', 'MIS', 'OVG', 'REC', 'PRE';
    print SCR "-----------------------------+";
    print SCR "--------+-------------+---------------\n";

    # �����Υ������Ȥ� Recall��Precision ��׻�����̤���Ϥ��� #
    my $tagname;
    foreach $tagname (@{$order->{$tag}}) {
	my $mis = $eval->{$tagname}{$document}{'GLD'} 
	- $eval->{$tagname}{$document}{'COR'};
	my $ovg = $eval->{$tagname}{$document}{'SYS'} 
	- $eval->{$tagname}{$document}{'COR'};
	my $rec;
	if (defined($eval->{$tagname}{$document}{'GLD'})) {
	    $rec = $eval->{$tagname}{$document}{'COR'} 
	    / $eval->{$tagname}{$document}{'GLD'} * 100;
	} else {
	    $rec = '-';
	}
	my $pre;
	if (defined($eval->{$tagname}{$document}{'SYS'})) {
	    $pre = $eval->{$tagname}{$document}{'COR'} 
	    / $eval->{$tagname}{$document}{'SYS'} * 100;
	} else {
	    $pre = '-';
	}

	# �����Υ������Ȥ� Recall��Precision ����� #
	if ($tagname eq $optional_tag) {
	    printf SCR "%-14s %6d ", 
	    $tagname, $eval->{$tagname}{$document}{'OPT'};
	    printf SCR "%6s ", '-';
	    if ($mis > 0) {
		printf SCR "| %6d ", $eval->{$tagname}{$document}{'COR'};
		printf SCR "| %5d %5s ", $mis, '-';
	    } else {
		printf SCR "| %6s ", '-';
		printf SCR "| %5s %5s ", '-', '-';
	    }
	} else {
	    printf SCR "%-14s %6d ", 
	    $tagname, $eval->{$tagname}{$document}{'GLD'};
	    printf SCR "%6d ", $eval->{$tagname}{$document}{'SYS'};
	    printf SCR "| %6d ", $eval->{$tagname}{$document}{'COR'};
	    printf SCR "| %5d %5d ", $mis, $ovg;
	}
	if ($rec eq '-' && $pre eq '-') {
	    printf SCR "| %6s %6s\n", $rec, $pre;
	} elsif ($rec eq '-') {
	    printf SCR "| %6s %6.2f\n", $rec, $pre;
	} elsif ($pre eq '-') {
	    printf SCR "| %6.2f %6s\n", $rec, $pre;
	} else {
	    printf SCR "| %6.2f %6.2f\n", $rec, $pre;
	}

	$all_gld += $eval->{$tagname}{$document}{'GLD'};
	$all_sys += $eval->{$tagname}{$document}{'SYS'};
	$all_cor += $eval->{$tagname}{$document}{'COR'};
	$all_mis += $mis;
	$all_ovg += $ovg;
    }

    # �Ƶ������Ȥ� f-measure ��׻� #
    if ($all_gld == 0) {
	$all_rec = '-';
    } else {
	$all_rec = $all_cor / $all_gld * 100;
    }
    if ($all_sys == 0) {
	$all_pre = '-';
    } else {
	$all_pre = $all_cor / $all_sys * 100;
    }
    if ($all_rec == 0 && $all_pre == 0) {
	$f = '-';
    } else {
	$f = 2 * $all_rec * $all_pre / ($all_rec + $all_pre);
    }

    # �Ƶ�����ɾ����̤���� #
    print SCR "-----------------------------+";
    print SCR "--------+-------------+---------------\n";
    printf SCR "%-14s ", 'ALL SLOTS';
    printf SCR "%6d %6d | %6d | %5d %5d ", 
    $all_gld, $all_sys, $all_cor, $all_mis, $all_ovg;
    if ($all_rec eq '-' && $all_pre eq '-') {
	printf SCR "| %6s %6s\n", $all_rec, $all_pre;
    } elsif ($all_rec eq '-') {
	printf SCR "| %6s %6.2f\n", $all_rec, $all_pre;
    } elsif ($all_pre eq '-') {
	printf SCR "| %6.2f %6s\n", $all_rec, $all_pre;
    } else {
	printf SCR "| %6.2f %6.2f\n", $all_rec, $all_pre;
    }
    if ($f eq '-') {
	printf SCR "%-61s%6s\n", 'F-MEASURES', $f;
    } else {
	printf SCR "%-61s%6.2f\n", 'F-MEASURES', $f;
    }
    
    if ($document eq 'ALL') {
	next;
    }

    print SCR "\n";

    #---------------------#
    # reportfile �ؤν��� #
    #---------------------#
    # Document number������������̾��ɽ�� #
    print REP "Document: $document\n";
    print REP "----------------------------------------";
    print REP "---------------------------------------\n";
    printf REP " %-7s%-16s%-16s%-6s\n", 'RESULT', 'OFFSET', 'TAG', 'STRING';
    printf REP "%15s%7s\n", '(start)', '(end)';
    print REP "----------------------------------------";
    print REP "---------------------------------------\n";
    
    # �Ƶ������Ȥ���Ƭ�����ݡ��Ȥ���� #
    my @item;
    foreach (keys %{$item->{$document}}) {
	my ($offset_start, $offset_end) = split(/$;/);
	push(@item, $offset_start);
    }
    my @item_sort = sort {$a <=> $b} @item;
    foreach (@item_sort) {
	foreach (@{$item->{$document}{$_}}) {
	    print REP $_;
	}
    }

    unless ($document eq $order->{$doc}[$#{$order->{$doc}}-1]) {
	print REP "\n";
    }
}

close(SCR);
close(REP);

exit(0);

# -----------------------------------------------------------------------------
# ���֥롼����
# -----------------------------------------------------------------------------
sub bless_ref {
  #--------------------------------#
  # Ϣ������ؤΥ�ե���󥹤���� #
  #--------------------------------#
  shift;
  my $self = {};
  bless $self;
} # bless_ref 

sub read_file {
  #--------------------#
  # �ե�������ɤ߹��� #
  #--------------------#
  my $self = shift;
  my $file = shift;
  my $num = 0;
  my $docnum;
  my $order = {};
  my $excluded = 0;
  open(FILE, $file) || die "Can't open $file: $!\n";
  while (<FILE>) {
    $num++;
    chomp;
    if (/^$comment/ || /^[\s]*$/) {
      next;
    } elsif (/^$tag (.+)$/) {
      push(@{$order->{$tag}}, $1);
    } elsif (/^$doc (\d+)$/) {
      $docnum = $1;
      $excluded = grep($docnum == $_, @exclude_docnum);
      if ($excluded > 0) {
	next;
      } else {
	$excluded = 0;
      }
      $self->{$docnum} = NESCR->bless_ref;
      push(@{$order->{$doc}}, $docnum);
    } elsif (/^$ind/ && $excluded == 0) {
      unless (defined($docnum)) {
	print "Warning: $doc is not defined. In line $num.\n";
      }

      # �ե����ޥåȤΥ����å�
      my $offset_start;
      my $offset_end;
      my $tag_start;
      my $tag_end;
      my $body;
      if (/^\@ (\d+) (\d+) \<$optional_tag[^\>]*\> \<\/([^\>]+)\> (.*)/) { 
	# OPTIONAL tag �ξ��
	$offset_start = $1;
        $offset_end = $2;
        $tag_start = $optional_tag;
        $tag_end = $3;
        $body = $4;
      } elsif (/^\@ (\d+) (\d+) \<([^\>]+)\> \<\/([^\>]+)\> (.*)/) {
	$offset_start = $1;
        $offset_end = $2;
        $tag_start = $3;
        $tag_end = $4;
        $body = $5;
      } else {
	print "Warning: Tag format is illegal. In line $num.\n";
      }
      my $offset = join($;, $offset_start, $offset_end);

      if ($tag_start eq $tag_end) {
	# �ե�����ξ������¸
	if (defined($body)) {
	  $self->{$docnum}{$offset} = join($;, $tag_start, $body);
	} else {
	  $self->{$docnum}{$offset} = join($;, $tag_start, 'NIL');
	}
      } else {
	print "Warning: Start tag name and end tag name don't correspond.";
	print " In line $num.\n";
      }
    } elsif($excluded > 0) {
      next;
    } else {
      print "Warning: Format is illegal. In line $num.\n";
    }
  }
  close(FILE);

  bless $order;
} # read_file
