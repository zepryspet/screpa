###########################################
########## MAIN ###########################
###########################################


#!/usr/bin/perl

use warnings;

#open the file config in read mode
open CONFIG, "<cfg.txt" or die $!;

#saving the configuration into a variable, so it's not recomendable for huge configurations. mostly will be ok ;)
my @conf=<CONFIG>;

#closing the config.txt file
close CONFIG;

#creating the HTML file in write mode and delete if already exist
open HTMLFILE, ">configuration.html" or die $!;

#writting the HTMLFILE and the style sheet CSS
css();

#writing the menu
menu();


#extracting the configurated zones
my @zones;					#array where the zones are stored
zone(\@zones, \@conf); 		#function to save the zones into the array


#creating the configured policies and creating the tables between the zones
say HTMLFILE '<h2 id\=\"policies\"> Policies </h2>';				#creating the table title
my ($i, $j);
my @zones1= @zones;
for($i=0; $i<@zones; $i++){
  for($j=0; $j<@zones1; $j++){
		if($i != $j){									#skiping if are the same element because the policy wil be written twice
		extract (\@conf, $zones[$i], $zones1[$j]);
		}
  }
}  
for($i=0; $i<@zones; $i++){								# extracting the intrazonal policies if someone is set, by default the FW permits the traffic
	extract (\@conf, $zones[$i], $zones1[$i]);
}	

#creating adresses, services and groups in HTML tables
groupadd(\@conf);
addresses(\@conf);
mip(\@conf);
vip(\@conf);
groupserv(\@conf);
services(\@conf);
    
#ending the HTMLFILE
bye();

#closing the HTMLFILE
close HTMLFILE;
#opening the result
 `configuration.html`;


###########################################
########## END  ###########################
###########################################




###########################################
########## SUBS ###########################
###########################################

#function to create the fisrt HTML headers and the style sheet CSS
sub css                       
{
say HTMLFILE '<!DOCTYPE html>';
say HTMLFILE '<html>';
say HTMLFILE '<head>';
say HTMLFILE '<title>Screenos configuration</title>';
say HTMLFILE '<style type="text/css">';
say HTMLFILE 'body {background-color:#F0F0F0 ;}';
say HTMLFILE 'h2 {color:#101010 ; padding: 6px; text-align:center;}';
say HTMLFILE 'h3 {color:#383838; padding: 0px 10px; text-align:center;}';
say HTMLFILE 'table {border-collapse:collapse; width:80%; margin-left: auto; margin-right: auto;}'; 	#positionig the table in the center
say HTMLFILE 'table,td,th {border:1px solid #C8C8C8; font-family: Arial; font-size: 12px; line-height: 1.7;}';													#Color border
say HTMLFILE 'th {background-color:#575FCC; color:white;padding: 6px 6px 6px 12px;}';
say HTMLFILE 'tr {color:gray;}'; 
say HTMLFILE 'td {padding: 4px 12px;}'; 
say HTMLFILE 'tr.odd {background-color:#DBE4FD;}';
say HTMLFILE 'tr.even {background-color:#CEDAFC;}';
say HTMLFILE 'tr.disabled {background-color:#F4BEBE;}';
say HTMLFILE 'input {margin: 45%;}';
say HTMLFILE 'td.id {text-align: center;}';
say HTMLFILE 'a:link {text-decoration:none;}';      	# unvisited link 
say HTMLFILE 'a:visited {text-decoration:none;}';      	# visited link 
say HTMLFILE 'a:hover {text-decoration:underline;}';   	# mouse over link 
say HTMLFILE 'a:active {text-decoration:underline;}';  	# selected link 
say HTMLFILE '#logo {margin-left: 30px;}';
######## Menu CSS
say HTMLFILE '#menu {font-family: Arial; font-size: 12px; height: 30px;}'; 
say HTMLFILE '#menu ul, li {list-style-type: none;}'; 
say HTMLFILE '#menu ul {position:absolute; left:390px; top:120px;}'; 
say HTMLFILE '#menu li {float: left;}'; 
say HTMLFILE '#menu a {text-decoration: none; color: #fff; background:#3176b0; display: block; padding: 8px 17px; text-align: center;}'; 
say HTMLFILE '#menu a:hover {background: #2262B8;}'; 
### FIN menu

say HTMLFILE '</style>';
say HTMLFILE '</head>';
say HTMLFILE '<body>';
}

### Horizontal Menu
sub menu
{
say HTMLFILE '<img id="logo" src="http://i41.tinypic.com/f4i348.jpg" alt="redit logo">';
say HTMLFILE '<div id="menu">';
  say HTMLFILE '<ul>';
     say HTMLFILE '<li><a href="#policies">Policies</a></li>';
     say HTMLFILE '<li><a href="#gaddresses">Group addresses</a></li>';
     say HTMLFILE '<li><a href="#addresses">Addresses</a></li>';
     say HTMLFILE '<li><a href="#nats">NATs</a></li>';
     say HTMLFILE '<li><a href="#gservices">Group services</a></li>';
     say HTMLFILE '<li><a href="#services">Services</a></li>';
  say HTMLFILE '</ul>';
say HTMLFILE '</div>';
}


#Function to extract the zones in the configuration, passing the arrays by reference
sub zone
{
my $zone = $_[0];
my $config = $_[1];
push(@$zone, '"Global"');    					#Saving the deafult global zone
for (my $i=0; $i<@$config; $i++){				#looking into the file line by line    
	if($$config[$i] =~ m/^set interface/){		#matching the "set interface"
		if($$config[$i] =~ m/zone/){			#also the line must include zone
			## spliting the line by spaces in order to divide its arguments
			my @zones= split(/\s+/, $$config[$i]);
			#checking if the zones aren't already created
			my $temp1= join(':',@$zone);		
			my $temp= pop(@zones);				#Saving the last value of the line (the zone)
					if($temp1 !~ m/$temp/){
					#Saving the last value of the line (the zone) into the array of zones
					push(@$zone, $temp);
					}
		}
	}
}
}



#########################
##### POLICY SUB ########
#########################

#function to extract the configurated policies in the zones
sub extract
{
my $config = $_[0];	#pointer to the config array
my $i=0; 			#Variable used in the two main loops
my $x = 0; 	    	#0= no policy, other indacates that at least one policy is created 
$zoneA= $_[1];
$zoneB= $_[2];
my $zone1 = $zoneA;
my $zone2 = $zoneB;
$zone1 =~ tr/\"//d;		#Removing the "" 
$zone2 =~ tr/\"//d;		#Removing the "" 
my ($num, $string);		#auxiliar variables
my $row= 'even';
#loop to look the policies between the zones 
for ($i=0; $i<@$config; $i++)
{     	
    if($$config[$i] =~ m/from $zoneA to $zoneB/)                     ## match "set policy" at the beginig and "from" wherever indicating that is a new policy
      {
	  if($x==0){
	    say HTMLFILE "<h3> From $zone1 to $zone2 </h3>";			#creating the table title
	    say HTMLFILE "<table>"; 								#creating the table
	    say HTMLFILE '<tr>';									#row	    
	    say HTMLFILE '<th> ID </th>';							#table titles
	    say HTMLFILE '<th> Disable </th>';
	    say HTMLFILE '<th> From </th>';
	    say HTMLFILE '<th> To </th>';
	    say HTMLFILE '<th> Services </th>';
	    say HTMLFILE '<th> Action </th>';
	    say HTMLFILE '<th> Name </th>';
	    say HTMLFILE '</tr>';
	    $x=1;								#changing the value to indacate that there are at least one policy	
	  }
		## spliting the first line by spaces in order to divide its arguments
		my @policy= split(/\s+/, $$config[$i]);  			#spliting by spaces
		my @comma= split(/\"+/, $$config[$i]);				#spliting by commas
      
		#saving the i value and detecting the end of the policy with the x variable
		my $x=$i;  		
		my $verify= 0;
		while($verify == 0){		
			while($$config[$x] !~ m/^exit/){ 
			$x++;				
			} 
			if($$config[$x+1] =~ m/^set policy id $policy[3]/){			# sometimes the policy could continue after the exit
			$x++;				
			} 
			else{	
			$verify=1;								# if not, just break the loop			
			}
		}
		####IDLE ROW####
		if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
		if($$config[$i+1] =~ m/disable/){
			$row= 'disabled';}
		#creating the policy row
		say HTMLFILE "<tr class\=\"$row\">";
    
		###############
		###### ID #####
		###############
		
		# extracting the id and putting it on the table
     		say HTMLFILE "<td class\=\"id\"> $policy[3] </td>";
		
		
		
		#################
		#disable? #######
		#################
		if($$config[$i+1] =~ m/disable/){
			say HTMLFILE '<td class="center"><input type="checkbox" checked></td>';
		}
		else{
			say HTMLFILE '<td class="center"><input type="checkbox"></td>';
		}
		
		###########
		#From######
		###########
		
		#extracting the from for the first line that define the policy
		say HTMLFILE '<td>';  										#opening td
		for($num=0; $num<@comma; $num++){
			if($zone1 eq $zone2){
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+4];					    #Saving the value
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
			else{
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+2];					    #Saving the value
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
		}
		#extracting the other sources below the line that define the policy, i.e "set src-addr"
		for($num=$i; $num<$x; $num++){
				if($$config[$num] =~ m/^set src-address/){
					my @source= split(/\"+/, $$config[$num]);	
					$string = $source[1];
					$string =~ tr/\"//d;							#Removing the "" 
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
				}
		}
		
		##################
		##### TO #########
		##################
		say HTMLFILE '<td>';  										#opening td
		for($num=0; $num<@comma; $num++){
			if($zone1 eq $zone2){
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+6];					    #Saving the value
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
			else{
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+4];					    #Saving the value
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
		}
		#extracting the other sources below the line that define the policy, i.e "set dst-addr"
		for($num=$i; $num<$x; $num++){
				if($$config[$num] =~ m/^set dst-address/){
					my @source= split(/\"+/, $$config[$num]);	
					$string = $source[1];
					$string =~ tr/\"//d;							#Removing the "" 
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
				}
		}
		
		say HTMLFILE '</td>';										#closing the td
		
		##################
		##### SERVICES ###
		##################
		say HTMLFILE '<td>';  										#opening td
		for($num=0; $num<@comma; $num++){
			if($zone1 eq $zone2){
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+8];					    #Saving the value
					$string =~ tr/\"//d;							#Removing the "" 	
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
			else{
				if($comma[$num] =~ m/$zone2/){
					$string = $comma[$num+6];					    #Saving the value
					$string =~ tr/\"//d;							#Removing the "" 	
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
					last; 											#breaking the loop
				}
			}
		}
		#extracting the other sources below the line that define the policy, i.e "set service"
		for($num=$i; $num<$x; $num++){
				if($$config[$num] =~ m/^set service/){
					my @source= split(/\"+/, $$config[$num]);				#
					$string = $source[1];
					$string =~ tr/\"//d;							#Removing the "" 
					say HTMLFILE "<div><a href\=\"\#$string\"> $string </a></div>";
				}
		}
		
		say HTMLFILE '</td>';										
		
		
		##########################
		###### ACTION ############
		##########################
		
		say HTMLFILE '<td>';  										#opening td
		$string= pop(@comma);
		if ($string =~ m/nat src permit/){									#nat src permit
		  say HTMLFILE '<a><img src="http://i43.tinypic.com/2irr8ug.gif" border="0" ></a>';
		}
		elsif ($string =~ m/permit/){										#permit
		  say HTMLFILE '<a><img src="http://i39.tinypic.com/2ilo6tx.gif" border="0" ></a>';
		}
		elsif ($string =~ m/deny/){											#deny
		  say HTMLFILE '<a><img src="http://i43.tinypic.com/2h3y7gp.gif" border="0" ></a>';
		}
		elsif ($string =~ m/pair-policy/){									#bidireccional VPN
		  say HTMLFILE '<a><img src="http://i42.tinypic.com/2nips2c.gif" border="0" ></a>';
		}
		elsif ($string =~ m/id/){											#VPN
		  say HTMLFILE '<a><img src="http://i41.tinypic.com/izm9w3.gif" border="0" ></a>';
		}
		
		###########LOG ################
		if ($string =~ m/log/){										#log
		  say HTMLFILE '<a><img src="http://i43.tinypic.com/316ulqr.gif" border="0"></a>';
		}
		
		say HTMLFILE '</td>';
		
		##########################
		######## NAME ############
		##########################	  
		say HTMLFILE '<td>';  										#opening td
		$string = $comma[0];
		if ($string =~ m/name/){
		say HTMLFILE $comma[1];
		}
		say HTMLFILE '</td>';
		#avoinding to read the already read policy
		$i=$x; 
      
		#ending the policy row
		say HTMLFILE '</tr>'; 
   } 
				
}
    #closing the table
    if($x==1){  
      say  HTMLFILE "</table>";
    }
    
}


#################################
##### ADDRESSES GROUPS SUB ######
#################################

sub groupadd{
my $config = $_[0];
my ($num, $i) = 0;
my $row= 'even';
say HTMLFILE "<h2 id\=\"gaddresses\"> Group addresses </h2>";			#creating the table title
say HTMLFILE '<table>'; 							#opening the table
say HTMLFILE '<tr>';
say HTMLFILE '<th> Group Name </th>';
say HTMLFILE '<th> Comment </th>';
say HTMLFILE '<th> Members </th>';
say HTMLFILE '</tr>';
for ($i=0; $i<@$config; $i++){
    if($$config[$i] =~ m/^set group address/){				#matching "set group address" in the line beggining
      my @comma= split(/\"+/, $$config[$i]);				#spliting the line by commas
	  ####################################
	  #### IDLE ROwW used in the style####
	  if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
      say HTMLFILE "<tr class\=\"$row\">";
	  #####################################
	  say HTMLFILE "<td id\=\"$comma[3]\"> $comma[3] </td>";
	  print HTMLFILE '<td>';
	  if(@comma>5){											#Printing the comment if anyone is configured
	  print HTMLFILE "$comma[5]";							#Printing the comment into the HTML file
	  }
	  say HTMLFILE '</td>';
	  print HTMLFILE '<td>';
      $i++;
      while($$config[$i] =~ m/\"$comma[3]\"/){									#looking for the same group name
		my @aux= split(/\"+/, $$config[$i]);									#spliting the next line by commas
		print HTMLFILE "<div><a href\=\"\#$aux[5]\"> $aux[5] </a> </div>";
		$i++;																	#reading the next line
	}
	  say HTMLFILE '</td>'; 
	  say HTMLFILE '</tr>';
	$i--;														#if doesn't match, reduces de index by 1, and the for started again. 
   }
}												#main for end
say HTMLFILE '</table>'; 						#closing the table
}												#Sub end

###########################
#### ADDRESSES  SUB #######
###########################
sub addresses{
my $config = $_[0];
my ($num, $i) = 0;
my $row= 'even';
say HTMLFILE "<h2 id\=\"addresses\"> Addresses </h2>";				#creating the table title
say HTMLFILE '<table>'; 						#opening the table
say HTMLFILE '<tr>';
say HTMLFILE "<th> Name </th>";
say HTMLFILE "<th>  IP </th>";
say HTMLFILE "<th>  Netmask </th>";
say HTMLFILE "<th>  Comment </th>";
say HTMLFILE '</tr>';
for ($i=0; $i<@$config; $i++){
    if($$config[$i] =~ m/^set address/){								#matching "set group address" in the line beggining
      my @comma= split(/\"+/, $$config[$i]);							#spliting the line by commas
	  my @space= split(/\s/, $comma[4]);			    				#spliting IP and the address by spaces
      ####################################
	  #### IDLE ROW used in the style####
	  if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
      say HTMLFILE "<tr class\=\"$row\">";
	  #####################################
	  say HTMLFILE "<td id\=\"$comma[3]\"> $comma[3] </td>";				#name with ID
	  say HTMLFILE "<td> $space[1] </td>";									#IP
	  if(@space > 2){														#If the object has a NETMASK
	  say HTMLFILE "<td> $space[2] </td>";									#Netmask
	  }
	  else{															#Printing one cell (used in damain names)
	  say HTMLFILE "<td> </td>";											
	  }
	  print HTMLFILE "<td>";
	  if(@comma > 5){
	  say HTMLFILE "$comma[5] ";										#Comments
	  }
	  print HTMLFILE "</td>";
	  say HTMLFILE '</tr>';
	}
}									#main for end
say HTMLFILE '</table>'; 						#closing the table
}

##############################
####### NATs #################
##############################

sub mip{
my $config = $_[0];
my $row= 'even';
say HTMLFILE "<h2 id\=\"nats\"> NATs </h2>";			#creating the table title
say HTMLFILE '<table>'; 				#opening the table
say HTMLFILE '<tr>';
say HTMLFILE '<th> Mapped IP </th>';
say HTMLFILE '<th> Host </th>';
say HTMLFILE '<th> Netmask </th>';
say HTMLFILE '</tr>';
for ($i=0; $i<@$config; $i++){
	if($$config[$i] =~ m/^set interface/ && $$config[$i] =~ m/mip/){				#matching "set interface" in the line beggining and the line includes "mip"
		my @space= split(/\s+/, $$config[$i]);					#spliting by spaces
		####################################
		#### IDLE ROW used in the style####
		if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
		say HTMLFILE "<tr class\=\"$row\">";
		#####################################
		say HTMLFILE "<td id\=\"MIP\($space[4]\)\"> $space[4] </td>";				#printing the MIP
		say HTMLFILE "<td> $space[6] </td>";				#printing the host
		say HTMLFILE "<td> $space[8] </td>";				#printing the netmask
		say HTMLFILE '</tr>';
	}
	else{
		if($$config[$i] =~ m/^set policy id/){		#matching "set policy id" in the line beggining
		last;										#breaking the loop if the policies starts
		}	
	}
	
}#for end
say HTMLFILE '</table>'; 						#closing the table
}


sub vip{
my $config = $_[0];
my $row= 'even';
say HTMLFILE '<table>'; 				#opening the table
say HTMLFILE '<tr>';
say HTMLFILE '<th> Virtual IP </th>';
say HTMLFILE '<th> Source port </th>';
say HTMLFILE '<th> Destination service </th>';
say HTMLFILE '<th> Translated IP </th>';
say HTMLFILE '</tr>';
for ($i=0; $i<@$config; $i++){
	if($$config[$i] =~ m/^set interface/ && $$config[$i] =~ m/vip/){				#matching "set interface" in the line beggining and the line includes "mip"
		my @space= split(/\s+/, $$config[$i]);					#spliting by spaces
		#detecting the end of the vip	
		my $x=$i;
			while($$config[$x] =~ m/^set interface $space[2] vip $space[4]/){
				$x++;	
			}
		my $numserv= $x -$i; 				#Calculating the numbers of lines of VIP
		####################################
		#### IDLE ROW used in the style####
		if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
		say HTMLFILE "<tr class\=\"$row\">";
		#####################################
		say HTMLFILE "<td id\=\"VIP\($space[4]\)\" rowspan\=\"$numserv\"> $space[4] </td>";				#printing the Virtual IP and the rowspan(HTML)
		say HTMLFILE "<td> $space[5] </td>";								#printing the Source port
		$space[6]=~ tr/\"//d;												#Removing the "" 	
		say HTMLFILE "<td><a href\=\"\#$space[6]\"> $space[6] </a></td>";	#printing the Destination service
		say HTMLFILE "<td> $space[7] </td>";								#printing the Translated IP
		say HTMLFILE '</tr>';
		if($numserv > 1 ){										#if there are more than one line of service configurated
				for(my $aux=$i+1; $aux<$x; $aux++){
					@space= split(/\s+/, $$config[$aux]);				#spliting the line by commas
					say HTMLFILE "<tr class\=\"$row\">";				#starting the row
					say HTMLFILE "<td> $space[6] </td>";				#printing the Source port
					$space[7]=~ tr/\"//d;								#Removing the ""
					say HTMLFILE "<td><a href\=\"\#$space[7]\"> $space[7] </a></td>";				#printing the Destination service
					say HTMLFILE "<td> $space[8] </td>";				#printing the Translated IP
					say HTMLFILE '</tr>';								#closing the row	
				}		
			}
		$i=$x - 1;					#Avoiding to read the already read lines
	}
	else{
		if($$config[$i] =~ m/^set policy id/){		#matching "set policy id" in the line beggining
		last;										#breaking the loop if the policies starts
		}	
	}
	
}#for end
say HTMLFILE '</table>'; 						#closing the table
}

#############################
###### SERVICES GROUPS ######
#############################

sub groupserv{
my $config = $_[0];
my $num = 0;
my $i= 0;
my $row= 'even';
say HTMLFILE "<h2 id\=\"gservices\"> Group services </h2>";			#creating the table title
say HTMLFILE '<table>'; 							#opening the table
say HTMLFILE '<tr>';
say HTMLFILE '<th> Group Name </th>';
say HTMLFILE '<th> Comment </th>';
say HTMLFILE '<th> Members </th>';
say HTMLFILE '</tr>';
for ($i=0; $i<@$config; $i++){
    if($$config[$i] =~ m/^set group service/){				#matching "set group address" in the line beggining
      my @comma= split(/\"+/, $$config[$i]);				#spliting the line by commas
      ####################################
	  #### IDLE ROW used in the style####
	  if($row eq 'even'){
			$row='odd';}
		else{
			$row= 'even';}
      say HTMLFILE "<tr class\=\"$row\">";
	  #####################################
	  say HTMLFILE "<td id\=\"$comma[1]\"> $comma[1] </td>";
	  print HTMLFILE '<td>';
	  if(@comma>3){											#Printing the comment if anyone is configured
	  print HTMLFILE "$comma[3]";							#Printing the comment into the HTML file
	  }
	  say HTMLFILE '</td>';
	  print HTMLFILE '<td>';
      $i++;
      while($$config[$i] =~ m/\"$comma[1]\"/){									#looking for the same group name
		my @aux= split(/\"+/, $$config[$i]);									#spliting the next line by commas
		print HTMLFILE "<div><a href\=\"\#$aux[3]\"> $aux[3] </a> </div>";
		$i++;																	#reading the next line
	}
	  say HTMLFILE '</td>'; 
	  say HTMLFILE '</tr>';
	$i--;														#if doesn't match, reduces de index by 1, and the for started again. 
   }
}												#main for end
say HTMLFILE '</table>'; 						#closing the table
}	




##############################
######### SERVICES ###########
##############################
sub services{
my $config = $_[0];				#pointer to the loaded configuration file
my $num= 0;
my $i=0;
my $service=0;
my $noread=0;
my $row= 'even';
say HTMLFILE "<h2 id\=\"services\"> Services </h2>";				#creating the table title
say HTMLFILE '<table>'; 						#opening the table
say HTMLFILE '<tr>';							#creating the table titles
say HTMLFILE "<th> Service name </th>";
say HTMLFILE "<th>  protocol </th>";
say HTMLFILE "<th>  source port </th>";
say HTMLFILE "<th>  destination port </th>";
say HTMLFILE "<th>  timeout </th>";
say HTMLFILE '</tr>';								
for ($i=0; $i<@$config; $i++){
    if($$config[$i] =~ m/^set service/){						#matching "set service" in the line beggining
	my @comma= split(/\"+/, $$config[$i]);						#spliting the line by commas
		if($$config[$i] =~ m/^set service \"$comma[1]\" protocol/){ #Forcing to read the first line of the service
			my @space= split(/\s+/, $comma[2]);						#spliting by spaces, this contains protocol, timeout, source and destination ports
			#detecting the end of the service	
			my $x=$i;
				while($$config[$x] =~ m/^set service \"$comma[1]\"/){
				$x++;	
				}
			$x--;								# the final line of the service is x
			########################
			#extracting the timeout#
			########################
			my $timeout= "default";						# default if there is no timeout
			my @lastline= split(/\"+/, $$config[$x]);	#spliting the line by commas
			my @time= split(/\s+/, $lastline[2]);		# spliting by spaces, here is where timeout is alocated
			if($time[1] eq "timeout"){					# if the timeout is alocated in the last line
				$timeout=$time[2];
				$x--;							#Don't read the last line of the service because is the timeout
				$noread=1;						#Used to indicate that the last line of the service is the timeout
			}
			else{								#if only one line is configurated the timeout is in the line end
				if(@space==9){		
				$timeout=$space[8];		
				}		
			}
			#################################						
			my $numserv= $x -$i + 1;
			####################################
			#### IDLE ROW used in the style####
			if($row eq 'even'){
					$row='odd';}
				else{
					$row= 'even';}
				say HTMLFILE "<tr class\=\"$row\">";
			#####################################
			say HTMLFILE "<td id\=\"$comma[1]\" rowspan\=\"$numserv\"> $comma[1] </td>";	#printing the service name and using rowspan and ID (HTML)
			say HTMLFILE "<td> $space[2] </td>";						#printing the protocol
			say HTMLFILE "<td> $space[4] </td>";						#printing the source port(s)
			say HTMLFILE "<td> $space[6] </td>";						#printing the destination port(s)
			say HTMLFILE "<td rowspan\=\"$numserv\"> $timeout </td>";	#Printing the timeout
			say HTMLFILE '</tr>';										#closing the row
			if($numserv > 1 ){										#if there are more than one line of service configurated
				for(my $aux=$i+1; $aux<=$x; $aux++){
					@comma= split(/\"+/, $$config[$aux]);			#spliting the line by commas
					@space= split(/\s+/, $comma[2]);				#spliting by spaces, this contains protocol, timeout, source
					say HTMLFILE "<tr class\=\"$row\">";								#starting the row
					say HTMLFILE "<td> $space[2] </td>";			#printing the protocol
					say HTMLFILE "<td> $space[4] </td>";			#printing the source port(s)
					say HTMLFILE "<td> $space[6] </td>";			#printing the destination port(s)
					say HTMLFILE '</tr>';							#closing the row	
				}		
			}	
	
			if($noread==1){		#if the last line isn't a timeout
			$i=$x++;		
			}
		}
	}	
	}								#main for end	
say HTMLFILE '</table>'; 			#closing the table
}			

##########################
###### VPN SUB ###########
##########################








#function to ending the HTMLFILE 
sub bye
{
say HTMLFILE '</body>';
say HTMLFILE '</html>';
}


 						
