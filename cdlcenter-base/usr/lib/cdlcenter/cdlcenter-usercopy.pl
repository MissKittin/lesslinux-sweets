#!/usr/bin/perl -w
# Author 			: Krzysztof Gibek ( jamar@desktop.pl )
# Create On 			: 2004:07:20
# Last Modified By 		: Michal Wrobel ( wrobel@task.gda.pl)
# Last Modified By		: 2005:10:11
# Version				: 0.2
# 
# Licensed under GPL ( see /usr/share/common-licenses/GPL for more details 
# or contact the Free Software Fundation for a copy ) www.gnu.org
# 


use strict;      

my $SECS_CHAR = "'";			# znak poczatku i konca nazwy sekcji
my $STD_SEP = ',' ;				# standardowy separator 

my $backup_prg_path = './cdlcenter-usercopy.new';

my $user_home_dir = $ENV {'HOME'};

my $main_config_file = '/etc/cdlcenter/usercopy.conf';	# w /etc

my $user_config_file = $user_home_dir.'/.cdlcenter/usercopy.conf';
my $user_set_file = $user_home_dir.'/.cdlcenter/usercopy.save';

#zmienne globalne
my @secs_all; 				# lista wszystkich dostepnych sekcji
my @secs_set;				# sekcje wybrane przez uzytkownika
my %files_all;				# wsystkie pliki w danej sekcji


return 1;
# GLOWNE PROCEDURY
sub init
{
	@secs_all = ();
	@secs_set = ();
	%files_all = ();
        
	#odczytaj plik z ustawieniami usera
	open (FH, $user_set_file) || die ("nie moge otworzyc $user_set_file");
	my @fc = <FH>;
	foreach my $fc (@fc){
		if (substr ($fc,0,1) eq $SECS_CHAR){
			#zapisz wybrane sekcje
			chop ($fc);
			$fc =~ s/'//g; #wytnij '
			push (@secs_set,  $fc);
		}    
 	}
    	close (FH);

    
	
	#odczytaj  plik konf. usera
	open (FH, $user_config_file) || die ("nie moge otworzyc $user_config_file");
	@fc = <FH>;

	my $act_sec;
	my $first;

	foreach my $fc (@fc){
		chop ($fc);
		#czy to poczatek nowej sekcji ?
		if (substr ($fc,0,1) eq "$SECS_CHAR"){
			$fc =~ s/'//g; #wytnij '
			$act_sec = $fc;
			push (@secs_all, $fc);
			$first = 1;
		}   
		# czy to komentarz ?
		elsif (substr ($fc,0,1) eq '#')	{	}
		# to musi byc sciezka
		else{	
			$files_all {$act_sec} .=  ($first eq 0) ? ("$STD_SEP") : ('') ; 
			$files_all {$act_sec} .= $fc;	
			$first = 0;
		} 
	}
    close (FH);
}#init

sub get_secs_all{
	return @secs_all;
}
 
sub get_files{
	my ($sec_name, $type) = @_;
	my @files = ();
	my $file="";
	
	my @tmp = split ("$STD_SEP", $files_all{$sec_name}||"" );	
	foreach $file (@tmp){
		push (@files, $1) if($file=~/(.*)\s+$type\s*$/);
	}
	return @files;
}

sub set_files{
	my ($sec_name_utf, $files) = @_;
	my $sec_name=encode("iso-8859-2",$sec_name_utf);
	$files_all{$sec_name}=encode("iso-8859-2",$files);
	&save_user_config_file(());
}

sub set_sec{
	my ($sec_name) = @_;
	
	if (!&in_array ($sec_name, @secs_all) ){
		push (@secs_all, $sec_name);
		return 0;
	}else{
		return 1;
	}
}

sub save_user_config_file{
	
	my (@secs_set) = @_;
	open (FH, ">$user_config_file") || die "nie moge zapisywac do $user_config_file";
	open (FH2, ">$user_set_file") || die "nie moge zapisuwac do $user_set_file";
	

	#sekcje
	foreach my $secs_all (@secs_all){
		print FH $SECS_CHAR . $secs_all ."$SECS_CHAR\n";
		if (&in_array ($secs_all, @secs_set) ){	
			print FH2 $SECS_CHAR . $secs_all ."$SECS_CHAR\n";	
		}
		
		#sciezki
		my @tmp = split ("$STD_SEP", $files_all {$secs_all});
	
		foreach my $tmp (@tmp){
			if ($tmp){
				print FH $tmp . "\n";
				if (&in_array ($secs_all, @secs_set) ){	
					print FH2 $tmp . "\n";	
				}
			}
		}
	}    
	close (FH);
	close (FH2);
}

 sub check_files
 {
  	my ($force) = @_;
	
	# czy istnieje lokalny plik z dostepnymi sekcjami ?
	if (! -e $user_config_file || $force)
	{
		if (! -e $main_config_file)
		{	`touch $main_config_file`;	}
		#else
		{	
			open (FH, $main_config_file);
			open (FH2, ">$user_config_file");
			my @tab = <FH>;
			for (my $i = 0 ; $i < @tab; $i++)
			{
				my $str = $tab[$i];
				#zamien USER_DIR na katalog usera
				$str =~ s/USER_DIR/$user_home_dir/g;
				print FH2 $str; 
			}
			close (FH);
			close (FH2);
		}
	if ($force)	{	&init();	}
	#exit();
	}

	if (! -e $user_set_file || $force)
	{
		#utworz pusty
		system ("touch $user_set_file");
	}
 }
 
 
#PROCEDURY POMOCNICZE

sub makebackup_do
{
	my ($options) = @_;
	system("$backup_prg_path $options");
	&rhs_msgbox ('Archiwizacja', "Archiwizacja zakoñczona" ,70);
	#exit();
}


sub files_edit_update 
{
	my ($sec_name, $file_name, $new_file_name) = @_;
	
	#plik czy katalog ?
	$new_file_name .= (-d $new_file_name) ? (' D') : (' F') ;
	
	my @tmp = split ("$STD_SEP", $files_all {$sec_name} );
	
	for (my $i = 0 ; $i < @tmp ; $i++)
	{	
		if (substr ($tmp[$i], 0,length ($tmp[$i]) - 2) eq $file_name)
		{
			$tmp[$i] = $new_file_name;	
		}	
		
	}	

	my $str;
	for (my $i = 0; $i < @tmp; $i++)
	{	$str .= $tmp[$i] . $STD_SEP;	}
	
	$files_all {$sec_name} = substr ($str,0,length($str)-1);

}

sub files_edit_delete 
{
	my ($sec_name, $file_name) = @_;
	
	
	my @tmp = split ("$STD_SEP", $files_all {$sec_name} );
	
	for (my $i = 0 ; $i < @tmp ; $i++)
	{	if (substr ($tmp[$i], 0,length ($tmp[$i]) - 2) eq $file_name)	{	$tmp[$i] = 'NULL';	}	}	

	my $str;
	for (my $i = 0; $i < @tmp; $i++)
	{	if ($tmp[$i] ne 'NULL') {	$str .= $tmp[$i] . $STD_SEP;	}	}
	
	$files_all {$sec_name} = substr ($str,0,length($str)-1);
}

sub files_edit_add
{
	my ($sec_name, $file_name) = @_;
	#plik czy katalog ?
	$file_name .= (-d $file_name) ? (' D') : (' F') ;
	
	if ($files_all {$sec_name} ne '')
	{	$files_all {$sec_name} .= "$STD_SEP";	}
	
	$files_all {$sec_name} .=  $file_name;
}

sub secs_add
{
	my ($sec_name) = @_;
	
	if (&in_array ($sec_name, @secs_all) )
	{
		&rhs_msgbox ('Dodawanie nowej sekcji', 'Sekcja o tej nazwie juÅ¼ istnieje. Wpisz inn± nazwê', 70);
	}
	else	{	push (@secs_all, $sec_name)	};
}

sub secs_delete
{
	my ($sec_name) = @_;
	my @tmp;
	
	for (my $i = 0 ; $i < @secs_all; $i++)
	{	if ($secs_all[$i] ne $sec_name) {push (@tmp, $secs_all [$i]);}	}

	delete $files_all {$sec_name};
	
	@secs_all = @tmp;	
}

sub in_array # ($igla, @tablica)
{
    my ($igla, @tablica) = @_;
    my $found = 0;
    
    for (my $z = 0 ; $z < @tablica; $z++)
    {
	$found =  ($tablica[$z] eq $igla || $found == 1) ? (1) : (0); 	
    }
    return ($found);
}



