#!/usr/bin/perl -w

# Author           : Michal Wrobel ( wrobel@task.gda.pl )
# Created On       : 2006.04.28
# Version          : 0.1.0
#
# Description      :
# Program wyszukuj±cy pliki LiLO i GRUBa i tworzacy na ich podstawie menu.lst
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)



use strict;

use constant MEDIAPATH => "/media/dyski";
our $DEVICEMAP="/tmp/tmp2/boot/grub/device.map";
our @winList="";

if( ! -e $DEVICEMAP ){
	die "'Plik $DEVICEMAP nie istnieje.'";
}

my @menuList=&scan();
my @menu;
@menu=&getUnique(\@menuList,&findRedundant(@menuList));
&changesNames(\@menu);


my %saw;
@winList = grep(!$saw{$_}++, @winList);

if(@winList) { push(@menu,&createWin); }
print "@menu\n";




sub partId(){
	my ($oldPart)=@_;
	my $partNo;
	$oldPart=~/^([^0-9]*)([^\s]*)/;
	my $dev=$1||"";
	my $dysk_id=`grep $dev $DEVICEMAP | cut -f 1`;
	$partNo=$2-1;
	$dysk_id=~s/\)\s*/,$partNo)/;
	return($dysk_id);

}

sub findLilo(){
	my ($dirToScan)=@_;
	my @menuEntry;
	my $entry="";
	my $title=0;
	my %lilo;
	$lilo{"image"}="";
	$lilo{"label"}="";
	$lilo{"initrd"}="";
	$lilo{"root"}="";
	$lilo{"append"}="";
	my $line="";
	
	open(FILE,"$dirToScan/etc/lilo.conf");
	while(<FILE>){
		$line=$_||"";
		if((!/^\s*#/)&&($line)){
			if(/^\s*image\s*=\s*(.*)/i){
				
				if(($lilo{"label"})&&($lilo{"image"})&&($lilo{"root"})){
					$entry="title\t\t".$lilo{"label"}."\n";
					$entry.="root\t\t".$lilo{"root"}."\n" if($lilo{"root"});
					$entry.="kernel\t\t".$lilo{"image"}." ".$lilo{"append"}."\n";
					$entry.="initrd\t\t".$lilo{"initrd"}."\n" if($lilo{"initrd"});
					$entry.="\n";
				}
				
				
				if($entry && $title){
					# TODO
					push(@menuEntry,$entry);
					$lilo{"image"}="";
					$lilo{"label"}="";
					$lilo{"initrd"}="";
					$lilo{"root"}="";
					$lilo{"append"}="";
				}
				$title=1;
				$lilo{"image"}=$1;
			}elsif(/^\s*initrd\s*=\s*(.*)/i){
				$lilo{"initrd"}=$1;
			}elsif(/^\s*append\s*=\s*(.*)/i){
				$lilo{"append"}=$1;
			}elsif(/^\s*label\s*=\s*(.*)/i){
				$lilo{"label"}=$1;
			}elsif(/^\s*root\s*=\s*(.*)/i){
				$lilo{"root"}=&partId($1);
			}elsif(/^\s*other\s*=\s*(.*)/i){
				$lilo{"image"}="";
				$lilo{"label"}="";
				$lilo{"initrd"}="";
				$lilo{"root"}="";
				$lilo{"append"}="";
			}
		}
	}
	close(FILE);
	return @menuEntry;
}

sub findGrub(){
	my ($dirToScan)=@_;
	my @menuEntry;
	my $entry="";
	my $title=0;
	my $line;
	open(FILE,"$dirToScan/boot/grub/menu.lst");
	while(<FILE>){
		$line=$_||"";
		if(/^\s*title/i){
			if($entry && $title){
				push(@menuEntry,$entry);
			}
			$title=1;
			$entry=$line;
		}elsif((!/^\s*#/)&&($line)){
			$entry=$entry.$line;
		}
	}
	close(FILE);
	return @menuEntry;
}


sub scan(){
	my @menuList;
	my @disks=glob(MEDIAPATH."/*");
	my $dir;
	my $dev;
	while(<@disks>){
		$dir=$_||"";
		if(-f "$dir/ls"){
			system("mount $dir");
			push(@menuList, &findLilo($dir)) if(-f "$dir/etc/lilo.conf");
			push(@menuList, &findGrub($dir)) if(-f "$dir/boot/grub/menu.lst");
			while(glob("$dir/*")){
				$dev=$dir;
				$dev=~s#/media/dyski#/dev#;
				push(@winList,$dev) if(/win/i);
			}
			system("umount $dir");
		}else{
			push(@menuList, &findLilo($dir)) if(-f "$dir/etc/lilo.conf");
			push(@menuList, &findGrub($dir)) if(-f "$dir/boot/grub/menu.lst");
			while(glob("$dir/*")){
				$dev=$dir;
				$dev=~s#/media/dyski#/dev#;
				push(@winList,$dev) if(/win/i);
			}
		}
		
	}
	return @menuList;
}

sub changesNames{
	my ($menu) = @_;
	for(my $count1=0;$count1<@$menu;$count1++){
		for(my $count2=$count1+1;$count2<@$menu;$count2++){
			$$menu[$count1]=~/title\s*([^\n]*)/s;
			my $label1=$1||0;
			$$menu[$count2]=~/title\s*([^\n]*)/s;
			my $label2=$1||0;
			$$menu[$count2]=~s/title\s*([^\n]*)/title\t\t $1-$count1$count2/m if($label1=~/^$label2$/);
		}
	}
	
}


sub getUnique{
	my ($all,@unique) = @_;
	my $element, my @ret, my $title;
IALL:	foreach $element (@unique){
		$element=~/^(.*) -%-/;
		$title=$1||"";
		foreach (@$all){
			if(/title\s*$title\n/s){	
				push @ret,$_;
				next IALL;
			}
		}
	}
	return @ret;
}



sub findRedundant(){
	my @table = @_;
	my %saw;
	for(my $count=0; $count < @table; $count++){
		
 		if(!($table[$count]=~s/^.*title\s*([^\n]*).*root\s*([^\n]*).*kernel\s*([^\s]*).*/$1 -%- $2 - $3/s)){
			$table[$count]="";
		}
	}
        undef %saw;
	@saw{@table} = ();
	return keys %saw;
}

sub createWin(){
	my $count=1;
	my @list;
	my $root;
	while(<@winList>){
		if($_){
			$root=&partId($_);
			push(@list,"title\t\tWindows-$count\nrootnoverify\t$root\nmakeactive\nchainloader +1");
		}
	}
	return @list;
}



