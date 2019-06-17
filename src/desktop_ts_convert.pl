#!/usr/bin/env perl
#
#  The desktop-ts-convert tool
#
#  Copyright (C) 2017 Deepin.Inc
#
#  desktop-ts-convert is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License 
#  version 3 published by the Free Software Foundation.
#

use warnings;
use strict;
use 5.018;

use XML::LibXML;
use Config::Tiny;
use File::Basename qw(basename);
use File::Path qw(make_path);

my @localeKeys = qw(Name GenericName Comment Keywords);

MAIN: {
    my $cmd = shift @ARGV // '';
    if ($cmd eq 'init') {
        my ($desktopFile, $outputTsDir) = @ARGV;
        Init($desktopFile, $outputTsDir);
    } elsif ($cmd eq 'desktop2ts') {
        my ($desktopFile, $outputTsDir) = @ARGV;
        Desktop2TS($desktopFile, $outputTsDir);
    } elsif ( $cmd eq 'ts2desktop' ) {
        my ($desktopFile, $tsDir, $outputDesktopFile) = @ARGV;
        TS2Desktop($desktopFile, $tsDir, $outputDesktopFile);
    } else {
        printHelp();
    }
    exit;
}

sub printHelp {
    my $bin = basename($0);
    print "
Usage:
init:
$bin init \$desktopFile \$outputTsDir
output source \$outputTsDir/desktop.ts and translation \$outputTsDir/desktop_<lang>.ts

desktop -> ts:
$bin desktop2ts \$desktopFile \$outputTsDir
output source \$outputTsDir/desktop.ts

ts -> desktop:
$bin ts2desktop \$desktopFile \$tsDir \$outputDesktopFile

document https://github.com/linuxdeepin/deepin-gettext-tools/blob/master/README.md
"
}

sub Desktop2TS {
    my ($file, $outputTsDir) = @_;
    my $contextName = 'desktop';
    my $desktopCfg = Config::Tiny->read($file, 'utf8');
    my $dom = createDocument();
    my $root = $dom->documentElement;
    my $context = getEmptyContext($dom, $contextName);
    my @msgs = createDesktopTsMessages($dom, $desktopCfg);
    $context->appendChild($_) for @msgs;
    # source
    make_path($outputTsDir);
    my $outputTsFile = "$outputTsDir/desktop.ts";
    say "output ts file: ", $outputTsFile;
    saveDocument($dom, $outputTsFile, 1);
}

sub Init {
    my ($file, $outputTsDir) = @_;
    my $contextName = 'desktop';
    my $desktopCfg = Config::Tiny->read($file, 'utf8');
    my $dom = createDocument();
    my $root = $dom->documentElement;
    my $context = getEmptyContext($dom, $contextName);
    my @msgs = createDesktopTsMessages($dom, $desktopCfg);
    $context->appendChild($_) for @msgs;
    # source
    make_path($outputTsDir);
    saveDocument($dom, "$outputTsDir/desktop.ts", 1);

    # translations
    my @langs = getDesktopLangs($desktopCfg);
    for my $lang ( @langs ) {
        my $langDom = createDocument($lang);
        my $langRoot = $langDom->documentElement;
        my $langContext = getEmptyContext($langDom, $contextName);

        ## fill translation
        my $sourceContextCopy = $context->cloneNode(1);
        ### $sourceContextCopy
        my @msgs = $sourceContextCopy->findnodes('./message');
        ### @msgs
        for my $msg (@msgs) {
            ### $msg

            my $translation = ($msg->findnodes('./translation[1]'))[0];
            die "not found translation" unless $translation;
            ### $translation
            
            my @locations = $msg->findnodes('./location');
            die "not found any location" unless @locations;
            for my $location (@locations) {
                my ($section, $key) = getSectionKeyWithLocationLang($location, $lang);
                my $value = $desktopCfg->{$section}{$key};
                if (defined $value) {
                    $translation->removeAttribute('type');
                    $translation->appendText($value);
                    # NOTE: 如果一条msg中包含了多个location，则获取了第一条有用的翻译后跳出循环
                    last;
                }
            }
        }
        $langContext->appendChild($_) for @msgs;
        
        saveDocument($langDom, "$outputTsDir/desktop_$lang.ts", 1);
    }
}

sub TS2Desktop {
    my ($desktopFile, $tsDir, $outputDesktopFile) = @_;
    my $contextName = 'desktop';
    my $desktopCfg = Config::Tiny->read($desktopFile, 'utf8');
    updateDesktopTranslation($desktopCfg , $contextName, $tsDir);
    writeDesktop($desktopCfg, $outputDesktopFile);
}

sub getEmptyContext {
    my ($dom, $contextNameStr) = @_;
    my $root = $dom->documentElement;
    my $context = findContext($root, $contextNameStr);
    if ($context) {
        my @oldMsgs = $context->findnodes('./message');
        $context->removeChild($_) for @oldMsgs;
    } else {
        # create context
        $context = createDesktopTsContext($dom, $contextNameStr);
        $root->appendChild($context);
    }
    return $context;
}

sub findContext {
    my ($root, $name) = @_;
    my @ctxNames = $root->findnodes('./context/name');
    for my $ctxName (@ctxNames) {
        my $ctxNameText = $ctxName->textContent;
        if ( $ctxNameText eq $name ) {
            return $ctxName->parentNode;
        }
    }
}

sub createDocument {
    my ($lang) = @_;
    my $dom = XML::LibXML::Document->new('1.0', 'utf-8');
    my $dtd = $dom->createInternalSubset('TS', undef, undef);
    # TS
    my $root = $dom->createElement('TS');
    $root->setAttribute('version', '2.1');
    if ($lang) {
        $root->setAttribute('language', $lang);
    }
    $dom->setDocumentElement($root);
    return $dom;
}

sub saveDocument {
    my ($dom, $file, $pretty) = @_;

    open FH, '>', $file
        or die "failed to open file $file for write: $!";
    print FH $dom->toString;
    close FH;
}

sub createDesktopTsContext {
    my ($dom, $contextNameStr) = @_;
    my $context = $dom->createElement('context');
    my $ctxName = $dom->createElement('name');
    $ctxName->appendText($contextNameStr);
    $context->appendChild($ctxName);
    return $context;
}


sub createDesktopTsMessages {
    my ($dom, $desktopCfg) = @_;
    
    # key: source, value: [ section . key, ... ]
    my %sourceSectionKeyMap;
    for my $section ( sort keys %$desktopCfg ) {
        # skip root section
        if ($section eq '_') {
            next;
        }

        for my $key (@localeKeys) {
            my $source = $desktopCfg->{$section}{$key};
            if ($source) {
                push @{ $sourceSectionKeyMap{$source}  }, "$section]$key";
            }
        }
    }
    ### %sourceSectionKeyMap
    my @msgs;

    for my $source (sort keys %sourceSectionKeyMap) {
        my $locations = $sourceSectionKeyMap{ $source };
        my $msg = createDesktopTsMessage($dom, $source, $locations);
        push @msgs, $msg;
    }
    return @msgs;
}

sub createDesktopTsMessage {
    my ($dom, $_source, $_locations) = @_;
    my $message = $dom->createElement('message');

    for my $_location (sort @$_locations ) {
        my $location = $dom->createElement('location');
        $location->setAttribute('filename', $_location);
        $location->setAttribute('line', 0);
        $message->appendChild($location);
    }

    my $source = $dom->createElement('source');
    $source->appendText($_source);
    $message->appendChild($source);

    my $translation = $dom->createElement('translation');
    $translation->setAttribute('type', 'unfinished');
    $message->appendChild($translation);

    return $message;
}

sub updateDesktopTranslation {
    my ($desktopCfg, $contextName, $tsDir) = @_;
    # remove locale keys
    for my $section (keys %$desktopCfg) {
        next if $section eq '_';
        for my $key (keys %{ $desktopCfg->{$section} }) {
            if ($key =~ /\[\w+\]/) {
                warn "remove $section $key";
                delete $desktopCfg->{$section}{$key};
            }
        }
    }

    # read translation
    my @files = getTranslationFiles($tsDir);
    for my $file ( @files ) {
        warn "read ts file $file";
        my $dom = XML::LibXML->load_xml(location => $file);
        my $root = $dom->documentElement;
        my $lang = $root->getAttribute('language');
        unless ($lang) {
            warn "language unknown in file $file";
            next;
        }

        my $context = findContext($root, $contextName);
        unless ($context) {
            warn "context not found in file $file";
            next;
        }
        
        my @msgs = $context->findnodes('./message');
        for my $msg (@msgs) {
            my $translation = ($msg->findnodes('./translation[1]'))[0];
            die "not found translation" unless $translation;

            my @locations = $msg->findnodes('./location');
            die "not found any location" unless @locations;
            for my $location ( @locations) {
                my $value = $translation->textContent;
                next unless $value;

                my ($section, $key) = getSectionKeyWithLocationLang($location , $lang);
                $desktopCfg->{$section}{$key} = $value;
            }
        }
    }
}

sub getTranslationFiles {
    my ($tsDir) = @_;
    glob "$tsDir/desktop_*.ts"; 
}

sub getDesktopLangs {
    my %langMap;
    my ($desktopCfg) = @_;
    for my $section (keys %$desktopCfg) {
        # skip root section
        next if $section eq '_';

        my $localeKeysJoined = join '|', @localeKeys;
        my $regex = qr/(?:$localeKeysJoined)\[(\w+)\]/;
        for my $key (keys %{ $desktopCfg->{$section} }) {
            ### $key
            if ( $key =~  $regex ) {
                my $lang = $1;
                $langMap{ $lang } = 1;
            }
        }
    }
    return keys %langMap;
}

sub getSectionKeyWithLocationLang {
    my ($location, $lang) = @_;
    my $filename = $location->getAttribute('filename');
    my ($section, $key) = split /\]/, $filename, 2;
    $key = $key."[$lang]";
    return $section, $key;
}

sub writeDesktop {
    my ($desktopCfg, $file) = @_;
    open my $fh, '>:utf8', $file
        or die $!;
    printDesktop($fh, $desktopCfg);
    close $fh;
}

sub printDesktop {
    my ($fh, $desktopCfg) = @_;

    my @sections = grep { $_ ne '_' } sort keys %$desktopCfg;
    my @sortedSections = ('Desktop Entry');
    # fill translation
    for (@sections) {
        push @sortedSections, $_
            if $_ ne 'Desktop Entry';
    }
    ### @sortedSections
    for my $section ( @sortedSections ) {
        say $fh "[$section]";
        my $sectionHash = $desktopCfg->{$section};

        my (@noTsKeys, @tsKeys);
        for (sort keys %$sectionHash) {
            if (/\[\w+\]/) {
                push @tsKeys, $_;
            } else {
                push @noTsKeys, $_;
            }
        }

        printSectionKeys($fh, $sectionHash, \@noTsKeys);

        if (@tsKeys) {
            say $fh "\n# Translations:\n# Do not manually modify!";
            printSectionKeys($fh, $sectionHash, \@tsKeys);
        }
        print $fh "\n";
    }
}

sub printSectionKeys {
    my ($fh, $sectionHash, $keys) = @_;
    for my $key ( @$keys ) {
        my $value = $sectionHash->{$key};
        $value =~ s/\n/ /g;
        say $fh "$key=$value"
            if $value;
    }
}

