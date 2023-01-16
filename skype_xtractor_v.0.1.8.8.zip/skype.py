# -*- coding: utf-8 -*-

#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	
# 								SKYPE XTRACTOR										#																	
# Developed by Nicodemo Gawronski for the Linux Forensics Distribution DEFT Linux	# 
# 																					#
# Extract messages (and more) from Skype main.db and chatsync files.				#
# This tool is open source under the GNU GPLv3 License.								#
# 																					#
# Please try Skype Xtractor and give feedback on my sourceforge page 				#
# or write me an email at nico[at]deftlinux[dot]net (italian or english)			#
#																					#
#																					#
# Enjoy!																			#	
#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	

import os, sqlite3, argparse, csv, webbrowser, base64, sync, re, sys, shutil
from datetime import datetime

def Csv_custom(values, this_report_csv_folder):
    TABLE = None
         
    #print('%r' % (values))
         
    #Get the name of the skype db file.
    mydatabase= values
    connection=sqlite3.connect(mydatabase)
    cursor=connection.cursor()
         
    #Get the name of each table in the database.
    cursor.execute('SELECT name FROM sqlite_master WHERE type="table"')

	#Save the names of each table.
    table_names = cursor.fetchall()
    #print table_names
    table_names = [["Messages"]]
	#For each table:
    for name in table_names:
        
		#Get the table's name. This variable is used for creating the file's name.
        TABLE = name[0]
             
        #DEBUG print TABLE
        #allentries is used to save the content of the table.
        allentries = ""
          
        cursor.execute('SELECT author,timestamp,body_xml,chatname FROM ' + TABLE)
        allentries=cursor.fetchall()
             
        if TABLE == "SMSes":
            print allentries
             
        #this variable contains the headers list.
        headers_list = [tuple[0] for tuple in cursor.description]
             
        count_rows = len(allentries)
        #The reason why you have empty columns is because the table is empty.
        try:
		    count_cols = len(allentries[0])
        except IndexError:
		    print(TABLE + " is an empty table!")
				 
        #DEBUG print count_rows, count_cols
        row=0
        col=0
             
        #Save the table to this file:
        #print this_report_csv_folder
        file_name = this_report_csv_folder + TABLE + ".csv"
             
        with open(file_name, 'wb') as f:
            toBeExported = []
            temp = []
            toBeExported.append(headers_list)
                 
            #For each row you have in your table:
            while row < count_rows:
                     
                #print ("Rows checked! " + str(i) + " " + str(count_rows) )
                     
                #while you have columns in your table, get all the entries.
                while col < count_cols:
                         
                         #print ("Cols checked! " + str(z) + " " + str(count_cols))
                         
                         #get the first value from allentries of this row and this column:
                    try_this = allentries[row][col]
                    #print try_this
						 #TODO buffer types.
						 #if the type of the value is a buffer type, just write buffer
                    if str(type(try_this)) == "<type 'buffer'>":
                        try_this = "buffer"
                         
                         #if the type of the value is None, don't waste chars and write an empty string.     
                    if str(type(try_this)) == "<type 'NoneType'>":
                        try_this = " " 
                         
                         #Try to encode the value as a string:
                    try:
                        try_this = str(try_this)
                             
                         #encode the string into utf-8 if you have a unicode error.     
                    except UnicodeEncodeError:
                        try_this = try_this.encode("utf-8")                       
                         #DEBUG print try_this    
                    #if the value is a timestamp 1374851641 convert it to date
                    length = len(try_this)
                    timestamp = ""
                    #print length
                    if length == 10:
                        try:
                            #print try_this
                            try_this = parse_date(try_this)
                #print t1,t2,t3, timestamp
                        except TypeError:
                            timestamp = " "
                        except ValueError:
				            timestamp = "Timestamp out of range: " + str(timestamp)
                            
                    try_this = try_this.replace("\t"," ",10).replace("\n"," ",10)	 
                    temp.append(try_this)
                         #Let's try the next column now!
                    col = col + 1
                     
                     #add the value to the list that has to be exported when we reach the bottom     
                toBeExported.append(temp)
                     
                     #Let's try the next row now...
                row = row + 1
                     #...and back to first column.
                col = 0                  
                temp = []
                 
                 #now write to the file the content of toBeExported list,    
            writer = csv.writer(f, delimiter="\t", lineterminator="\n\r")
            writer.writerows(toBeExported)
                 
                 #close the file.
            f.close()
                   
        
         #close the db.
    cursor.close()


def Csv(values, this_report_csv_folder):
    TABLE = None
         
    #print('%r' % (values))
         
    #Get the name of the skype db file.
    mydatabase= values
    connection=sqlite3.connect(mydatabase)
    cursor=connection.cursor()
         
    #Get the name of each table in the database.
    cursor.execute('SELECT name FROM sqlite_master WHERE type="table"')

	#Save the names of each table.
    table_names = cursor.fetchall()
    #print table_names
         
	#For each table:
    for name in table_names:
        
		#Get the table's name. This variable is used for creating the file's name.
        TABLE = name[0]
             
        #DEBUG print TABLE
        #allentries is used to save the content of the table.
        allentries = ""
          
        cursor.execute('SELECT * FROM ' + TABLE)
        allentries=cursor.fetchall()
             
        if TABLE == "SMSes":
            print allentries
             
        #this variable contains the headers list.
        headers_list = [tuple[0] for tuple in cursor.description]
             
        count_rows = len(allentries)
        #The reason why you have empty columns is because the table is empty.
        try:
		    count_cols = len(allentries[0])
        except IndexError:
		    print(TABLE + " is an empty table!")
				 
        #DEBUG print count_rows, count_cols
        row=0
        col=0
             
        #Save the table to this file:
        #print this_report_csv_folder
        file_name = this_report_csv_folder + TABLE + ".csv"
             
        with open(file_name, 'wb') as f:
            toBeExported = []
            temp = []
            toBeExported.append(headers_list)
                 
            #For each row you have in your table:
            while row < count_rows:
                     
                #print ("Rows checked! " + str(i) + " " + str(count_rows) )
                     
                #while you have columns in your table, get all the entries.
                while col < count_cols:
                         
                         #print ("Cols checked! " + str(z) + " " + str(count_cols))
                         
                         #get the first value from allentries of this row and this column:
                    try_this = allentries[row][col]
						 
						 #TODO buffer types.
						 #if the type of the value is a buffer type, just write buffer
                    if str(type(try_this)) == "<type 'buffer'>":
                        try_this = "buffer"
                         
                         #if the type of the value is None, don't waste chars and write an empty string.     
                    if str(type(try_this)) == "<type 'NoneType'>":
                        try_this = " " 
                         
                         #Try to encode the value as a string:
                    try:
                        try_this = str(try_this)
                             
                         #encode the string into utf-8 if you have a unicode error.     
                    except UnicodeEncodeError:
                        try_this = try_this.encode("utf-8")                       
                         #DEBUG print try_this    

						 
                    temp.append(try_this)
                         #Let's try the next column now!
                    col = col + 1
                     
                     #add the value to the list that has to be exported when we reach the bottom     
                toBeExported.append(temp)
                     
                     #Let's try the next row now...
                row = row + 1
                     #...and back to first column.
                col = 0                  
                temp = []
                 
                 #now write to the file the content of toBeExported list,    
            writer = csv.writer(f, delimiter=",", lineterminator="\n\r")
            writer.writerows(toBeExported)
                 
                 #close the file.
            f.close()
                   
        
         #close the db.
    cursor.close()

class Account:
	
	# init
	def __init__(self, record, a_id, skypename, displayname, fullname, birthday, gender, img, city, province,
	 country, lastonline_timestamp,home_phone, office_phone, mobile_phone, emails, homepage, about, creation_date, mood_text, lastused_timestamp, avatar, avatar_timestamp):
		    
         global this_report_complete_tree
         #record
         self.record = self.parse_text(record)
         #contact id
         self.a_id = self.parse_text(a_id)
        
         #Skypename
         self.skypename = self.parse_text(skypename)
        
         #Displayname
         self.displayname = self.parse_text(displayname)
         #Fullname
         self.fullname = self.parse_text(fullname)
        
         #Birthday
         self.birthday = self.parse_text(birthday)
         #print self.birthday
         if self.birthday == "None" or self.birthday == "0":
             self.birthday = " "
         elif self.birthday.isdigit() is True:
             #print self.birthday
             year = self.birthday[0:4]
             month = self.birthday[4:6]
             day = self.birthday[6:8]
             self.birthday = day+"-"+month+"-"+year
        
         #Parse various date times.
         self.lastonline_timestamp = parse_date(lastonline_timestamp)
         self.lastused_timestamp = parse_date(lastused_timestamp)
         self.avatar_timestamp = parse_date(avatar_timestamp)
         
         #Use a different parser because the date is not like 1202680620 but like 20044677,
         #both equal to 2008-02-10 21:57:00
         self.creation_date = self.parse_creation(creation_date)
        
        
         #Gender
         self.img, self.gender = check_gender(gender)	
        
        
         #city text
         self.city = self.parse_text(city)
        
         #province text
         self.province = self.parse_text(province)
        
         #country text
         self.country = self.parse_text(country)
        
         #home_phone text
         self.home_phone = self.parse_text(home_phone)
        
         #office_phone text
         self.office_phone = self.parse_text(office_phone)
        
         #mobile_phone text
         self.mobile_phone = self.parse_text(mobile_phone)
        
         #emails text
         self.emails = self.parse_text(emails)
        
         #homepage text
         self.homepage = self.parse_text(homepage)
        
         #about text        
         self.about = self.parse_text(about)        
        
         #mood text
         self.mood_text = self.parse_text(mood_text)
        
         #avatar image
         #Save the avatar image to a img/avatar/ folder.
         #This image is named by (contact_id)_avatar.jpg
         #Change the value of self.avatar to path+(id)_avatar.jpg
        
         self.avatar = avatar
         output_avatar = this_report_complete_tree+self.a_id+"_avatar.jpg"
         if self.avatar != None:
             with open(output_avatar, "wb") as o:
                
                 o.write(self.avatar[1:])    
                 o.close()
                 self.avatar = "avatar/"+self.a_id+"_avatar.jpg"
         else:
		  	 self.avatar = " "        
        
       
			
        
        
        def __str__(self):
            id_to_string = self.c_id
            skypename_to_string = self.skypename
            mood_to_string = self.mood_text

            return id_to_string, skypename_to_string, mood_to_string
        
        

        #Parse text method
        def parse_text(self, value):    
            try:
                value = str(value)
                if "<script" in value:
					value = "<textarea>"+value+"</textarea>"
                if value == "None":
				    value = " "
            except UnicodeEncodeError:
                value = value.encode("utf-8")
            return value
        	
        
        
        def parse_creation (self,value):
            try:
                value = value*60
                value = datetime.fromtimestamp(value)
                value = datetime.strptime(str(value), '%Y-%m-%d %H:%M:%S')
                value = value.strftime('%d-%m-%Y %H:%M:%S')
            except TypeError:
                value = " "
            return value
			   
class Transfer:
	
	
	
	#init
    def __init__(self, record, t_id, partner_handle, partner_dispname, filename, file_type, filepath,
        filesize, bytestransferred, starttime, endtime, status):
			
			
			#call record
            self.record = self.parse_text(record)
			#call id
            self.t_id = self.parse_text(t_id)
            
            #Parse various date times.
            self.starttime = parse_date(starttime)
            self.endtime = parse_date(endtime)
            
            self.partner_handle = self.parse_text(partner_handle)
            
            self.partner_dispname = self.parse_text(partner_dispname)

            
            self.filename = self.parse_text(filename)            
            
            self.file_type = self.check_type(file_type)          
            
            self.filepath = self.parse_text(filepath)  
            self.filesize = self.parse_text(filesize)  
            self.bytestransferred = self.parse_text(bytestransferred)  
            self.status = self.check_status(status)  
            
    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if "<script" in value:
                value = "<textarea>"+value+"</textarea>"
            if value == "None":
			    value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value
        
    def check_type(self, value):
		if value == 1:
			value = "Incoming File Transfer"
		elif value == 2:
			value = "Outgoing File Transfer"
		return value		                   
    def check_status(self, value):
		if value == 8:
			value = "Completed"
		elif value == 7:
			value = "Aborted From Destination"	
		elif value == 10:
			value = "Aborted From Origin"	
					
		return value
    
class Call:
	
	
	
	#init
    def __init__(self, record, c_id, begin_timestamp, duration, call_type, call_type_img, host_identity, remote_host, remote_host_displayname, status ):
			
			
			#call record
            self.record = self.parse_text(record)
			#call id
            self.c_id = self.parse_text(c_id)
            
            #Parse various date times.
            self.begin_timestamp = parse_date(begin_timestamp)
            
            #Duration
            #convert the call duration from seconds to minutes:seconds.

            self.duration = self.convert_seconds(duration)
            
            self.call_type_img = self.parse_text(call_type_img)

            
            self.call_type = self.check_call_type(call_type)
            
            
            self.host_identity = self.parse_text(host_identity)
            self.remote_host = self.parse_text(remote_host)
            self.host_identity = self.check_host(host_identity, remote_host)
            
            
            
            self.remote_host = self.parse_text(remote_host)  
            self.status = self.check_status(status)  
            
            self.remote_host_displayname = self.parse_text(remote_host_displayname)     
            
                       
    def check_status(self, value):
		if value == 6:
			value = "Accepted"
		elif value == 8:
			value = "Rejected at Destination"
		elif value == 13 or value == 7:
			value = "Cancelled at Origin"
		else:
			value = "Other status - Not recognized "			
		return value
    def __str__(self):
        id_to_string = self.c_id
        host_identity_to_string = self.host_identity
        remote_host_to_string = self.remote_host

        return id_to_string, host_identity_to_string, remote_host_to_string
                
        #I'm getting the local host name from the guid field, like:  
        #jessicaleone2-nicodemo.j.gawronski-1347550499-1 where one of the names is the host name.
        #remove the remote_host identity, any digit and all the "-":           
    def check_host(self, host_to_convert, remote_host): 
        
        if host_to_convert != None:
            try:
                split1, split2, split3, split4 = host_to_convert.split("-")
                if split1 == remote_host:
				    host_to_convert = split2
                else:
                    host_to_convert = split1	
            except:
				print("there was an error converting the host! skipping..")
				return remote_host
            #print split1, split2, split3, split4, host_to_convert
        else:
			host_to_convert = " "
        return host_to_convert

    def check_call_type(self, value):
		if value == 1:
			value = "Incoming"
			self.call_type_img = "../../resources/incoming.png"
		elif value == 2:
			value = "Outgoing"
			self.call_type_img = "../../resources/outgoing.png"
		return value	

	#convert the call duration from seconds to minutes:seconds.
    def convert_seconds(self, value):
		try:
			seconds = value%60
			minutes = value/60
			hours = 0
			if minutes >= 60:
				hours = minutes/60
				minutes = minutes%60
			if minutes < 10:
				minutes = "0"+str(minutes)
			if hours < 10:
				hours = "0"+str(hours)	
			if seconds < 10:
				seconds = "0"+str(seconds)	
					
			value = str(hours)+ ":" +str(minutes)+ ":" +str(seconds)
		except TypeError:
			value = " "
		return value			

    def parse_text(self, value):    
        try:
            value = str(value)
            if "<script" in value:
                value = "<textarea>"+value+"</textarea>"
            if value == "None":
			    value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value
			   			    
class Contact:

    # init
    def __init__(self, record, c_id, skypename, displayname, birthday, lastonline_timestamp, is_permanent,isblocked, isauthorized, availability, final_status, gender, img, city, province, country, home_phone, office_phone, mobile_phone, emails, homepage, about,
    profile_timestamp, mood_text, lastused_timestamp, avatar_timestamp, avatar):
        
        global this_report_complete_tree
        #record
        self.record = self.parse_text(record)
        
        #contact id
        self.c_id = self.parse_text(c_id)
        
        #Skypename
        self.skypename = self.parse_text(skypename)
        
        #Displayname
        self.displayname = self.parse_text(displayname)
        
        #Birthday
        self.birthday = str(birthday)
        if self.birthday == "None":
            self.birthday = " "
        elif self.birthday.isdigit() is True:
            #print self.birthday
            year = self.birthday[0:4]
            month = self.birthday[4:6]
            day = self.birthday[6:8]
            self.birthday = day+"-"+month+"-"+year
        
        #Parse various date times.
        self.lastonline_timestamp = parse_date(lastonline_timestamp)
        self.lastused_timestamp = parse_date(lastused_timestamp)
        self.avatar_timestamp = parse_date(avatar_timestamp)
        self.profile_timestamp = parse_date(profile_timestamp)

        

		#Check contact status
        self.is_permanent = self.parse_text(is_permanent)
        self.isblocked = self.parse_text(isblocked)
        self.isauthorized = self.parse_text(isauthorized)
        self.availability = self.parse_text(availability)    
        self.final_status = self.check_status(is_permanent, isblocked, isauthorized, availability)
        
        #Gender
        self.img, self.gender = check_gender(gender)	
        
        
        #city text
        self.city = self.parse_text(city)
        
        #province text
        self.province = self.parse_text(province)
        
        #country text
        self.country = self.parse_text(country)
        
        #home_phone text
        self.home_phone = self.parse_text(home_phone)
        
        #office_phone text
        self.office_phone = self.parse_text(office_phone)
        
        #mobile_phone text
        self.mobile_phone = self.parse_text(mobile_phone)
        
        #emails text
        self.emails = self.parse_text(emails)
        
        #homepage text
        self.homepage = self.parse_text(homepage)
        
        #about text        
        self.about = self.parse_text(about)        
        
        #mood text
        self.mood_text = self.parse_text(mood_text)
        
        #avatar image
        #Save the avatar image to a img/avatar/ folder.
        #This image is named by (contact_id)_avatar.jpg
        #Change the value of self.avatar to path+(id)_avatar.jpg
        
        self.avatar = avatar
        output_avatar = this_report_complete_tree+self.c_id+"_avatar.jpg"
        if self.avatar != None:
            with open(output_avatar, "wb") as o:
                
                o.write(self.avatar[1:])    
                o.close()
                self.avatar = "avatar/"+self.c_id+"_avatar.jpg"
        else:
			self.avatar = " "        
        
       
			
        
        
    def __str__(self):
        id_to_string = self.c_id
        skypename_to_string = self.skypename
        mood_to_string = self.mood_text

        return id_to_string, skypename_to_string, mood_to_string        
		
    def check_status(self, is_permanent, isblocked, isauthorized, availability):
        stat = []
        stat = [is_permanent, isblocked, isauthorized, availability]
        result = ""
        #print self.skypename, stat
        if stat[0] == 1 and stat[1] == None and stat[2] == 1 and stat[3] != 8:
			result = "Usual Contact"
        elif stat[0] == 1 and stat[1] == None and stat[2] == 1 and stat[3] == 8:
			result = "In your list but never seen online"
        elif stat[0] == 1 and stat[1] == None and stat[2] == None:
            result = "Deleted"
        elif stat[0] == 1 and stat[1] == 1:
            result = "Blocked"
        elif stat[0] == 0:
            result = "Not in your contact list, probably seen in a group chat"
        #if stat[3] == 8:
            #print self.skypename, stat, result  
        #print result							
        return result

    
    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if "<script" in value:
					value = "<textarea>"+value+"</textarea>"
            if value == "None":
				value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value

class Chat_message:
	


	
	#init
    def __init__(self, record, m_id, timestamp, time_ux, author, from_dispname, mess, status, mess_type, chatname, dialog_partner,edited_timestamp):
			
			
			#message record
            self.record = self.parse_text(record)
			#message id
            self.m_id = self.parse_text(m_id)
            
            #Parse various date times.
            self.timestamp = parse_date(timestamp)
            self.time_ux = time_ux
            #print time_ux
            
            #author and displayname

            self.author = self.parse_text(author)
            self.from_dispname = self.parse_text(from_dispname)

            
            self.mess = self.parse_text(mess)           
            self.status = self.check_status(status)          
                       
            self.mess_type = self.check_type(mess_type)  
            self.chatname = self.parse_text(chatname)  
            
            self.edited_timestamp = parse_date(edited_timestamp)
                 
            self.dialog_partner = self.parse_text(dialog_partner)
            
    def __str__(self):
        mess_to_string = self.mess
        
        return mess_to_string

    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if value == "None":
				value = " "
            if '<' in value:
                value = value.replace('<', '&lt;')
            if '<ss type="tongueout">:P</ss>' in value:
                value = value.replace('<ss type="tongueout">:P</ss>', ':P')
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value      
        
    def check_status(self, value):
		if value == 4:
			value = "Read"
		if value == 3:
			value = "Not Read"
		elif value == 2:
			value = "Sent"	
		elif value == 1:
			value = "Not Delivered Yet"	
		return value	
	
    def check_type(self, value):
		if value == 2:
			value = "CHAT PICTURE CHANGED"
		if value == 61:
			value = "POSTED_TEXT"
		if value == 50:
			value = "Auth_Request"
		if value == 51:
			value = "Auth_Granted"		
		if value == 53:
			value = "Auth_Denied"		
		if value == 30:
			value = "STARTED_LIVESESSION"		
		if value == 39:
			value = "ENDED_LIVESESSION"		
		if value == 68:
			value = "FILE TRANSFER"		
		if value == 110:
			value = "BIRTHDAY"		
		return value			           			             	

class Chat_summary:
	


	
	#init
    def __init__(self, record, chatname, total, first_time, last_time):
			
			
			#message record
            self.record = str(record)
			#message id
            self.chatname = str(chatname)
            
            #Parse various date times.
            self.first_time = parse_date(first_time)
            self.last_time = parse_date(last_time)
            
            #author and displayname

            self.total = total
                        
            
    def __str__(self):
        mess_to_string = self.mess
        
        return mess_to_string

    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if value == "None":
				value = " "
            if '<ss type="tongueout">:P</ss>' in value:
                value = value.replace('<ss type="tongueout">:P</ss>', ':P')
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value      
        
    def check_status(self, value):
		if value == 4:
			value = "Read"
		if value == 3:
			value = "Not Read"
		elif value == 2:
			value = "Sent"	
		elif value == 1:
			value = "Not Delivered Yet"	
		return value	
	
    def check_type(self, value):
		if value == 2:
			value = "CHAT PICTURE CHANGED"
		if value == 61:
			value = "POSTED_TEXT"
		if value == 50:
			value = "Auth_Request"
		if value == 51:
			value = "Auth_Granted"		
		if value == 53:
			value = "Auth_Denied"		
		if value == 30:
			value = "STARTED_LIVESESSION"		
		if value == 39:
			value = "ENDED_LIVESESSION"		
		if value == 68:
			value = "FILE TRANSFER"		
		if value == 110:
			value = "BIRTHDAY"		
		return value			           			             	

class Group_chat:
	


	
	#init
    def __init__(self, record, c_id, name, participants, posters, active_members, friendlyname, timestamp,
      last_change):
			
			
			#message record
            self.record = self.parse_text(record)
			#message id
            self.c_id = self.parse_text(c_id)
            
      
            self.name = self.parse_text(name)
            self.participants = self.parse_text(participants)
            self.posters = self.parse_text(posters)
            self.active_members = self.parse_text(active_members)
            self.friendlyname = self.parse_text(friendlyname)
            
            #Parse various date times.
            self.timestamp = parse_date(timestamp)
            self.last_change = parse_date(last_change)
            
            

    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if value == "None":
				value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value      
     
class Voicemail:
	


	
	#init
    def __init__(self, record, v_id, partner_handle, partner_dispname, subject, timestamp, duration, allowed_duration,
      size, path, failures, convo_id):
			
			
			#message record
            self.record = str(record)
			#message id
            self.v_id = str(v_id)
            
      
            self.partner_handle = partner_handle
            self.partner_dispname = partner_dispname
            self.subject = subject
            self.duration = duration
            self.allowed_duration = allowed_duration
            self.size = self.parse_text(size)
            self.path = path
            self.failures = failures
            self.convo_id = convo_id
            
            #Parse various date times.
            self.timestamp = parse_date(timestamp)
            
            

    #Parse text method
    def parse_text(self, value):    
        try:
            value = str(value)
            if value == "None":
				value = " "
        except UnicodeEncodeError:
            value = value.encode("utf-8")
        return value      

############################################## 
# GET the data from the SQLITE3 Tables, NOW! # 
        
def get_accounts(in_file):    
    account_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row
    cursor=connection.cursor()
       
    #Get the name of each table in the database.
    cursor.execute('SELECT * FROM Accounts')
    
    accounts = cursor.fetchall()
    
    for account in accounts:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Accounts TABLE  #
        # ------------------------------------------------------- #
        # accounts[0] --> id						accounts[1] --> is_permanent 				accounts[2] --> status
		# accounts[3] --> pwdchangestatus			accounts[4] --> logoutreason 				accounts[5] --> commitstatus
		# accounts[6] --> suggested_skypename		accounts[7] --> skypeout_balance_currency 	accounts[8] --> skypeout_balance
		# accounts[9] --> skypeout_precision		accounts[10] --> skypein_numbers 			accounts[11] --> subscriptions
		# accounts[12] --> cblsyncstatus			accounts[13] --> offline_callforward 		accounts[14] --> chat_policy
		# accounts[15] --> skype_call_policy		accounts[16] --> pstn_call_policy 			accounts[17] --> avatar_policy
		# accounts[18] --> buddycount_policy		accounts[19] --> timezone_policy 			accounts[20] --> webpresence_policy
		# accounts[21] --> phonenumbers_policy		accounts[22] --> voicemail_policy 			accounts[23] --> authrequest_policy
		# accounts[24] --> ad_policy				accounts[25] --> partner_optedout 			accounts[26] --> service_provider_info
		# accounts[27] --> registration_timestamp	accounts[28] --> nr_of_other_instances 		accounts[29] --> partner_channel_status
		# accounts[30] --> flamingo_xmpp_status		accounts[31] --> federated_presence_policy 	accounts[32] --> owner_under_legal_age
		# accounts[33] --> type						accounts[34] --> skypename 					accounts[35] --> pstnnumber
		# accounts[36] --> fullname					accounts[37] --> birthday 					accounts[38] --> gender
		# accounts[39] --> languages				accounts[40] --> country 					accounts[41] --> province
		# accounts[42] --> city						accounts[43] --> phone_home 				accounts[44] --> phone_office
		# accounts[45] --> phone_mobile				accounts[46] --> emails 					accounts[47] --> homepage
		# accounts[48] --> about					accounts[49] --> profile_timestamp 			accounts[50] --> received_authrequest
		# accounts[51] --> displayname				accounts[52] --> refreshing 				accounts[53] --> given_authlevel
		# accounts[54] --> aliases					accounts[55] --> authreq_timestamp 			accounts[56] --> mood_text
		# accounts[57] --> timezone					accounts[58] --> nrof_authed_buddies 		accounts[59] --> ipcountry
		# accounts[60] --> given_displayname		accounts[61] --> availability 				accounts[62] --> lastonline_timestamp
		# accounts[63] --> capabilities				accounts[64] --> avatar_image 				accounts[65] --> assigned_speeddial
		# accounts[66] --> lastused_timestamp		accounts[67] --> authrequest_count 			accounts[68] --> assigned_comment
		# accounts[69] --> alertstring				accounts[70] --> avatar_timestamp 			accounts[71] --> mood_timestamp
		# accounts[72] --> rich_mood_text			accounts[73] --> synced_email 				accounts[74] --> set_availability
		# accounts[75] --> options_change_future	accounts[76] --> cbl_profile_blob 			accounts[77] --> authorized_time
		# accounts[78] --> sent_authrequest			accounts[79] --> sent_authrequest_time 		accounts[80] --> sent_authrequest_serial
		# accounts[81] --> buddyblob				accounts[82] --> cbl_future 				accounts[83] --> node_capabilities
		# accounts[84] --> node_capabilities_and	accounts[85] --> revoked_auth 				accounts[86] --> added_in_shared_group
		# accounts[87] --> in_shared_group			accounts[88] --> authreq_history 			accounts[89] --> profile_attachments
		# accounts[90] --> stack_version			accounts[91] --> offline_authreq_id 		accounts[92] --> verified_email
		# accounts[93] --> verified_company			accounts[94] --> liveid_membername 			accounts[95] --> roaming_history_enabled
        
        
        
        record = len(account_list)
        curr_account = Account(record, account["id"], account["skypename"], account["displayname"], account["fullname"], account["birthday"], account["gender"], None, account["city"], account["province"], account["country"], account["lastonline_timestamp"], 
        account["phone_home"], account["phone_office"], account["phone_mobile"], account["emails"], account["homepage"], account["about"], account["registration_timestamp"],  account["mood_text"], account["lastused_timestamp"], account["avatar_image"], account["avatar_timestamp"],)        
        account_list.append(curr_account)
    return account_list

def get_transfers(in_file):
    
    transfers_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row

    cursor=connection.cursor()
       
    cursor.execute('SELECT * FROM Transfers')
    
    transfers = cursor.fetchall()
    
    for transfer in transfers:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Transfers TABLE  #
        # ------------------------------------------------------- #
        # transfer[0] --> id				transfer[1] --> is_permanent 		transfer[2] --> type
		# transfer[3] --> partner_handle	transfer[4] --> partner_dispname 	transfer[5] --> status
		# transfer[6] --> failurereason		transfer[7] --> starttime 			transfer[8] --> finishtime
		# transfer[9] --> filepath			transfer[10] --> filename 			transfer[11] --> filesize
		# transfer[12] --> bytestransferred	transfer[13] --> bytespersecond 	transfer[14] --> chatmsg_guid
		# transfer[15] --> chatmsg_index	transfer[16] --> convo_id 			transfer[17] --> pk_id
		# transfer[18] --> nodeid			transfer[19] --> last_activity 		transfer[20] --> flags
		# transfer[21] --> old_status		transfer[22] --> old_filepath 		transfer[23] --> accepttime
        
        record = len(transfers_list)
                	
        curr_trans = Transfer(record, transfer["id"], transfer["partner_handle"], transfer["partner_dispname"], transfer["filename"], transfer["type"], transfer["filepath"],
        transfer["filesize"], transfer["bytestransferred"], transfer["starttime"], transfer["finishtime"], transfer["status"])
        transfers_list.append(curr_trans)
    return transfers_list

def get_calls(in_file):
    
    call_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row
    cursor=connection.cursor()
       
    #Get the name of each table in the database.
    cursor.execute('SELECT * FROM CallMembers')
    
    calls = cursor.fetchall()
    
    for call in calls:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** CallMembers TABLE  #
        # ------------------------------------------------------- #
        # call[0] --> id					call[1] --> is_permanent 		call[2] --> identity
		# call[3] --> dispname				call[4] --> languages 			call[5] --> call_duration
		# call[6] --> price_per_minute		call[7] --> price_precision 	call[8] --> price_currency
		# call[9] --> payment_category		call[10] --> type 				call[11] --> status
		# call[12] --> failurereason		call[13] --> sounderror_code 	call[14] --> soundlevel
		# call[15] --> pstn_statustext		call[16] --> pstn_feedback 		call[17] --> forward_targets
		# call[18] --> forwarded_by			call[19] --> debuginfo 			call[20] --> videostatus
		# call[21] --> target_identity		call[22] --> mike_status 		call[23] --> is_read_only
		# call[24] --> quality_status		call[25] --> call_name 			call[26] --> transfer_status
		# call[27] --> transfer_active		call[28] --> transferred_by 	call[29] --> transferred_to
		# call[30] --> guid					call[31] --> next_redial_time 	call[32] --> nrof_redials_done
		# call[33] --> nrof_redials_left	call[34] --> transfer_topic 	call[35] --> real_identity
		# call[36] --> start_timestamp		call[37] --> is_conference 		call[38] --> quality_problems
		# call[39] --> identity_type		call[40] --> country 			call[41] --> creation_timestamp
		# call[42] --> stats_xml			call[43] --> is_premium_video_sponsor 		call[44] --> is_multiparty_video_capable
		# call[45] --> recovery_in_progress	call[46] --> nonse_word 		call[47] --> pk_status                       
		
        record = len(call_list)
        	
        curr_call = Call(record, call["id"], call["creation_timestamp"], call["call_duration"], call["type"], None, call["guid"],
        call["identity"], call["dispname"], call["status"])
        call_list.append(curr_call)
    return call_list

def get_contacts(in_file):
    
    contact_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row

    cursor=connection.cursor()
       
    #Get the name of each table in the database.
    cursor.execute('SELECT * FROM Contacts')
    
    contacts = cursor.fetchall()
    
    for contact in contacts:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Contacts TABLE  #
        # ------------------------------------------------------- #
        # contacts[0] --> id				 	contacts[1] --> is_permanent 		contacts[2] --> type
		# contacts[3] --> skypename			 	contacts[4] --> pstnnumber 		contacts[5] --> aliases
		# contacts[6] --> fullname			 	contacts[7] --> birthday 		contacts[8] --> gender
		# contacts[9] --> languages			 	contacts[10] --> country 		contacts[11] --> province
		# contacts[12] --> city				 	contacts[13] --> phone_home 		contacts[14] --> phone_office
		# contacts[15] --> phone_mobile		 	contacts[16] --> emails 		contacts[17] --> homepage
		# contacts[18] --> about			 	contacts[19] --> avatar_image 		contacts[20] --> mood_text
		# contacts[21] --> rich_mood_text	 	contacts[22] --> timezone 		contacts[23] --> capabilities
		# contacts[24] --> profile_timestamp 	contacts[25] --> nrof_authed_buddies 		contacts[26] --> ipcountry
		# contacts[27] --> avatar_timestamp	 	contacts[28] --> mood_timestamp 		contacts[29] --> received_authrequest
		# contacts[30] --> authreq_timestamp 	contacts[31] --> lastonline_timestamp 		contacts[32] --> availability
		# contacts[33] --> displayname		 	contacts[34] --> refreshing 		contacts[35] --> given_authlevel
		# contacts[36] --> given_displayname 	contacts[37] --> assigned_speeddial 		contacts[38] --> assigned_comment
		# contacts[39] --> alertstring		 	contacts[40] --> lastused_timestamp 		contacts[41] --> authrequest_count
		# contacts[42] --> assigned_phone1	 	contacts[43] --> assigned_phone1_label 		contacts[44] --> assigned_phone2
		# contacts[45] --> assigned_phone2_labelcontacts[46] --> assigned_phone3 	contacts[47] --> assigned_phone3_label
		# contacts[48] --> buddystatus			contacts[49] --> isauthorized 		contacts[50] --> popularity_ord
		# contacts[51] --> isblocked			contacts[52] --> authorization_certificate 		contacts[53] --> certificate_send_count
		# contacts[54] --> account_modification_serial_nr		contacts[55] --> saved_directory_blob 		contacts[56] --> nr_of_buddies
		# contacts[57] --> server_synced		contacts[58] --> contactlist_track 		contacts[59] --> last_used_networktime
		# contacts[60] --> authorized_time		contacts[61] --> sent_authrequest 		contacts[62] --> sent_authrequest_time
		# contacts[63] --> sent_authrequest_serial		contacts[64] --> buddyblob 		contacts[65] --> cbl_future
		# contacts[66] --> node_capabilities	contacts[67] --> revoked_auth 		contacts[68] --> added_in_shared_group
		# contacts[69] --> in_shared_group		contacts[70] --> authreq_history 		contacts[71] --> profile_attachments
		# contacts[72] --> stack_version		contacts[73] --> offline_authreq_id 		contacts[74] --> node_capabilities_and
		# contacts[75] --> authreq_crc			contacts[76] --> authreq_src 		contacts[77] --> pop_score
		# contacts[78] --> authreq_nodeinfo		contacts[79] --> main_phone 		contacts[80] --> unified_servants
		# contacts[81] --> phone_home_normalized		contacts[82] --> phone_office_normalized 		contacts[83] --> phone_mobile_normalized
		# contacts[84] --> sent_authrequest_initmethod		contacts[85] --> authreq_initmethod contacts[86] --> verified_email
		# contacts[87] --> verified_company		contacts[88] --> sent_authrequest_extrasbitmask 		contacts[89] --> extprop_tags		
        record = len(contact_list)
        
                 	
        curr_contact = Contact(record, contact["id"], contact["skypename"], contact["displayname"], contact["birthday"], contact["lastonline_timestamp"], contact["is_permanent"], contact["isblocked"], contact["isauthorized"], contact["availability"], None,
        contact["gender"], None, contact["city"], contact["province"], contact["country"], contact["phone_home"], contact["phone_office"], contact["phone_mobile"], contact["emails"], contact["homepage"], contact["about"], contact["profile_timestamp"], contact["mood_text"], contact["lastused_timestamp"], contact["avatar_timestamp"], contact["avatar_image"] )
        contact_list.append(curr_contact)
    return contact_list

def get_chat_messages(in_file):
    
    chat_messages_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row

    cursor=connection.cursor()
       
    cursor.execute('SELECT * FROM Messages')
    
    messages = cursor.fetchall()
    
    for message in messages:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Messages TABLE  #
        # ------------------------------------------------------- #
        # message[0] --> id					message[1] --> is_permanent message[2] --> convo_id
		# message[3] --> chatname			message[4] --> author 		message[5] --> from_dispname
		# message[6] --> author_was_live	message[7] --> guid 		message[8] --> dialog_partner
		# message[9] --> timestamp			message[10] --> type 		message[11] --> sending_status
		# message[12] -->consumption_status	message[13] --> edited_by 	message[14] --> edited_timestamp
		# message[15] --> param_key			message[16] --> param_value message[17] --> body_xml
		# message[18] --> identities		message[19] --> reason 		message[20] --> leavereason
		# message[21] --> participant_count	message[22] --> error_code 	message[23] --> chatmsg_type
		# message[24] --> chatmsg_status	message[25] --> body_is_rawxml 		message[26] --> oldoptions
		# message[27] --> newoptions		message[28] --> newrole 	message[29] --> pk_id
		# message[30] --> crc				message[31] --> remote_id 	message[32] --> call_guid

        record = len(chat_messages_list)
        	
        curr_mess = Chat_message(record, message["id"], message["timestamp"], message["timestamp"], message["author"], message["from_dispname"], message["body_xml"], message["chatmsg_status"], message["type"],
         message["chatname"], message["dialog_partner"] , message["edited_timestamp"] )
        chat_messages_list.append(curr_mess)
    return chat_messages_list

def get_chat_summary(chat_messages_list, this_report_pages_folder, in_file):
    
    chat_summary_list = []
    short_list = []
    total = 0
    glob_tot = 0
    #Get the name of the skype db file.
    now = date_me()
    #print now

    for m in chat_messages_list:
        
        
        
        if m.chatname not in short_list:
            short_list.append(m.chatname)
            total_short = 1
            short_list.append(total_short)
            short_list.append("")
        else:
            index_short_list = short_list.index(m.chatname)
            total_short = short_list[index_short_list+1]
            short_list[index_short_list+1]= total_short+1
    now = date_me()
   
    
    leng = len(short_list)/3
    q = 0
    while q < len(short_list):
        glob_tot = glob_tot+short_list[q+1]
        q = q+3
    a = 0
    while a < len(short_list):
        mydatabase= in_file
        connection=sqlite3.connect(mydatabase)
        connection.row_factory = sqlite3.Row
        cursor=connection.cursor()
        cursor.execute('SELECT type FROM Chats WHERE name ="{}"'.format(short_list[a]))
        type_ = ""    
        type_ = cursor.fetchone()
        t = []
        try:
            type_ = type_[0]
        except:
            type_ = 2     
        if type_ == 2:
            try:
                clean_name = short_list[a]
                clean_index = short_list[a].index(";")
                clean_name = short_list[a][:clean_index].replace("#","")
                u1,u2 = clean_name.split("/$",1)
                t.append(u1)
                t.append(u2)
                t.sort()
                clean_name = t[0]+"_"+t[1]
                short_list[a+2] = clean_name
            except:
                clean_name = short_list[a]+"_"
                short_list[a+2] = clean_name
                #print("Do you have problems with this chat?. Type=2 e nome= "+str(short_list[a]))
        else:
            clean_name = short_list[a]+"_"
            short_list[a+2]= clean_name 

        
        a = a+3
    
    already_parsed = ["DONE",]
    a = 2
    count = 0

    while a < len(short_list):
        
        if short_list[a] not in already_parsed:
            count = short_list.count(short_list[a])
            already_parsed.append(short_list[a])
            
            b = 0
            parse = short_list[a]
            temp = []
            
            total = 0
            chat_summary_list.append(short_list[a]) # CLEAR_CHATNAME --> Chat_list_summary[0]
            chat_summary_list.append(total) # Total messages for this group of chat --> chat_list_summary[1]
            chat_summary_list.append(0) #1 Placeholder for min timestamp --> chat_summary_list[2]
            chat_summary_list.append(0) #2 Placeholder for min timestamp --> chat_summary_list[3]
            chat = short_list[a][:]+".html"
            ILLEGAL = ["<",">",":",'"',"/","\\","|","?","*", "#"]
            
            for char in chat:
                index = chat.index(char)
                if chat[index] in ILLEGAL:
                    chat = chat.replace(char, "_")
                
            chat_summary_list.append(chat) # CHAT file_name.html --> chat_summary_list[4]
            cursor.execute('SELECT participants FROM Chats WHERE name ="{}"'.format(short_list[a-2]))
            participants = ""    
            participants = cursor.fetchone()
            if not participants:
			    participants = short_list[a-2]
            else:
                participants = participants[0]
            chat_summary_list.append(participants) # Participants --> chat_summary_list[5]

            chat_summary_list.append("") # Placeholder for parsed_chats --> chat_summary_list[6]
            chat_summary_list.append("") # Placeholder for size --> chat_summary_list[7]
            
            while b < count:
                index = short_list.index(parse)
                this_chat = short_list[index-2]
                tot = short_list[index-1]
                
                this_chat_index = chat_summary_list.index(parse)
                this_chat_index = this_chat_index+6
                
                chat_summary_list[this_chat_index-5] =chat_summary_list[this_chat_index-5]+tot
                chat_summary_list[this_chat_index] =chat_summary_list[this_chat_index]+" "+ this_chat
                
                cursor.execute('SELECT MAX(timestamp) FROM Messages WHERE chatname ="{}"'.format(this_chat))
                max_date = cursor.fetchone()
                cursor.execute('SELECT MIN(timestamp) FROM Messages WHERE chatname ="{}"'.format(this_chat))
                min_date = cursor.fetchone()
                
                
                if chat_summary_list[this_chat_index-4] == 0:
                    chat_summary_list[this_chat_index-4] =min_date[0]
                elif min_date[0] < chat_summary_list[this_chat_index-4]:
                    chat_summary_list[this_chat_index-4] =min_date[0]
                
                if chat_summary_list[this_chat_index-3] == 0:
                    chat_summary_list[this_chat_index-3] =max_date[0]
                elif max_date[0] > chat_summary_list[this_chat_index-3]:
                    chat_summary_list[this_chat_index-3] =max_date[0]

                cursor.execute('SELECT * FROM Messages WHERE chatname ="{}"'.format(this_chat))
                messages = cursor.fetchall()
                record = 1

                for message in messages:
                    
                
                    curr_mess = Chat_message(record, message["id"], message["timestamp"], message["timestamp"], message["author"], message["from_dispname"], message["body_xml"], message["chatmsg_status"], message["type"],
                    message["chatname"], message["dialog_partner"] , message["edited_timestamp"] )
                    record = record+1
                
                    temp.append(curr_mess)
      
                short_list[index] = "DONE"

                b = b+1
       
            size = create_single(chat, temp, this_report_pages_folder)
            
            size = round(size/1024.0, 2)      
            size = str(size)+" Kb"   
            chat_summary_list[this_chat_index+1] = size
      
        else:
            already_parsed.append(short_list[a])
        a = a +3    

    chat_summary_list.append(glob_tot)

    return chat_summary_list, short_list  	
    
def get_group_chat(in_file):
    
    group_chat_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row

    cursor=connection.cursor()
       
    cursor.execute('SELECT * FROM Chats WHERE type = 4')
    
    chats = cursor.fetchall()
    
    for chat in chats:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Chats TABLE  #
        # ------------------------------------------------------- #
        # chat[0] --> id						chat[1] --> is_permanent 		chat[2] --> name
		# chat[3] --> options					chat[4] --> friendlyname 		chat[5] --> description
		# chat[6] --> timestamp					chat[7] --> activity_timestamp	chat[8] --> dialog_partner
		# chat[9] --> adder						chat[10] --> type 				chat[11] --> mystatus
		# chat[12] --> myrole					chat[13] --> posters 			chat[14] --> participants
		# chat[15] --> applicants				chat[16] --> banned_users 		chat[17] --> name_text
		# chat[18] --> topic					chat[19] --> topic_xml 			chat[20] --> guidelines
		# chat[21] --> picture					chat[22] --> alertstring 		chat[23] --> is_bookmarked
		# chat[24] --> passwordhint				chat[25] --> unconsumed_suppressed_msg 		chat[26] --> unconsumed_normal_msg
		# chat[27] --> unconsumed_elevated_msg	chat[28] --> unconsumed_msg_voice chat[29] --> activemembers
		# chat[30] --> state_data				chat[31] --> lifesigns 			chat[32] --> last_change
		# chat[33] --> first_unread_message		chat[34] --> pk_type 			chat[35] --> dbpath


        record = len(group_chat_list)
        curr_chat = Group_chat(record, chat["id"], chat["name"], chat["participants"], chat["posters"], chat["activemembers"], chat["friendlyname"], chat["timestamp"],
          chat["last_change"])
        group_chat_list.append(curr_chat)
    return group_chat_list

def get_voicemails(in_file):
    
    voicemails_list = []
	
    #Get the name of the skype db file.
    mydatabase= in_file
    connection=sqlite3.connect(mydatabase)
    connection.row_factory = sqlite3.Row

    cursor=connection.cursor()
       
    cursor.execute('SELECT * FROM Voicemails')
    
    voicemails = cursor.fetchall()
    
    for voice in voicemails:
		
		# ------------------------------------------------------- #
        #  Skype main.db file *** Voicemails TABLE  #
        # ------------------------------------------------------- #
        # voice[0] --> id				voice[1] --> is_permanent 		voice[2] --> type
		# voice[3] --> partner_handle	voice[4] --> partner_dispname 	voice[5] --> status
		# voice[6] --> failurereason	voice[7] --> subject 			voice[8] --> timestamp
		# voice[9] --> duration			voice[10] --> allowed_duration 	voice[11] --> playback_progress
		# voice[12] --> convo_id		voice[13] --> chatmsg_guid 		voice[14] --> notification_id
		# voice[15] --> flags			voice[16] --> size 				voice[17] --> path
		# voice[18] --> failures		voice[19] --> vflags 			voice[20] --> xmsg


        record = len(voicemails_list)
        curr_voice = Voicemail(record, voice["id"], voice["partner_handle"], voice["partner_dispname"], voice["subject"], voice["timestamp"], voice["duration"], voice["allowed_duration"],
          voice["size"], voice["path"], voice["failures"], voice["convo_id"]	)
        voicemails_list.append(curr_voice)
    return voicemails_list

##################################
# CREATE HTML PAGES WITH CONTENT #

def create_accounts_page(account_list, this_report_pages_folder):
    now = date_me()
    sys.stdout.write(now+": Creating Account page...")

    name = "accounts.html"
    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
   
    
    
    #GENERATE CONTENT
    # writes 1st table header "Accounts"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Id</th>\n'.encode('utf-8'))
    wfile.write('<th>Avatar</th>\n'.encode('utf-8'))
    wfile.write('<th>Contact Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Display Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Fullname</th>\n'.encode('utf-8'))
    wfile.write('<th>Birthday - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Last Seen Online - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Gender</th>\n'.encode('utf-8'))
    wfile.write('<th>City</th>\n'.encode('utf-8'))
    wfile.write('<th>Province</th>\n'.encode('utf-8'))
    wfile.write('<th>Country</th>\n'.encode('utf-8'))
    wfile.write('<th>Home Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Office Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Mobile Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Email(s)</th>\n'.encode('utf-8'))
    wfile.write('<th>Homepage</th>\n'.encode('utf-8'))
    wfile.write('<th>About</th>\n'.encode('utf-8'))
    wfile.write('<th>Profile Creation Date - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Mood Text</th>\n'.encode('utf-8'))
    wfile.write('<th>Last Used Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Avatar Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    # writes 1st table content
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in account_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.a_id))
        wfile.write('<td><img src="{}"></td>\n'.format(i.avatar))
        wfile.write('<td>{}</td>\n'.format(i.skypename))
        wfile.write('<td>{}</td>\n'.format(i.displayname))
        wfile.write('<td>{}</td>\n'.format(i.fullname))
        wfile.write('<td>{}</td>\n'.format(i.birthday))
        wfile.write('<td>{}</td>\n'.format(i.lastonline_timestamp))
        wfile.write('<td><p hidden>{}</p><img src="{}"></td>\n'.format(i.gender, i.img))
        wfile.write('<td>{}</td>\n'.format(i.city))
        wfile.write('<td>{}</td>\n'.format(i.province))
        wfile.write('<td>{}</td>\n'.format(i.country))
        wfile.write('<td>{}</td>\n'.format(i.home_phone))
        wfile.write('<td>{}</td>\n'.format(i.office_phone))
        wfile.write('<td>{}</td>\n'.format(i.mobile_phone))
        wfile.write('<td>{}</td>\n'.format(i.emails))
        wfile.write('<td>{}</td>\n'.format(i.homepage))
        wfile.write('<td>{}</td>\n'.format(i.about))
        wfile.write('<td>{}</td>\n'.format(i.creation_date))
        wfile.write('<td>{}</td>\n'.format(i.mood_text))
        wfile.write('<td>{}</td>\n'.format(i.lastused_timestamp))
        wfile.write('<td>{}</td>\n'.format(i.avatar_timestamp))

        
        wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    wfile.close()
    print ("done!")

def create_transfer_page(transfers_list, this_report_pages_folder):
    now = date_me()    
    sys.stdout.write(now+": Creating Transfer page...")

    name = "transfers.html"
    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Transfer id</th>\n'.encode('utf-8'))
    wfile.write('<th>Partner Handle</th>\n'.encode('utf-8'))
    wfile.write('<th>Partner Displayname</th>\n'.encode('utf-8'))
    wfile.write('<th>Filename</th>\n'.encode('utf-8'))
    wfile.write('<th>File type</th>\n'.encode('utf-8'))
    wfile.write('<th>File Path</th>\n'.encode('utf-8'))
    wfile.write('<th>File Size</th>\n'.encode('utf-8'))
    wfile.write('<th>Bytes Transferred</th>\n'.encode('utf-8'))
    wfile.write('<th>Start Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Finish Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Status</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_transfer id" value="Search transfer id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_partner_handle" value="Search partner handle" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_partner_disp" value="Search partner dispname" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_filename" value="Search filename" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_filetype" value="Search file type" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_filepath" value="Search file path" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_filesize" value="Search file size" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_bytes" value="Search bytes transferred " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_start" value="Search start" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_finish" value="Search finish" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in transfers_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.t_id))
        wfile.write('<td>{}</td>\n'.format(i.partner_handle))
        wfile.write('<td>{}</td>\n'.format(i.partner_dispname))
        wfile.write('<td>{}</td>\n'.format(i.filename))
        wfile.write('<td>{}</td>\n'.format(i.file_type))
        wfile.write('<td>{}</td>\n'.format(i.filepath))
        wfile.write('<td>{}</td>\n'.format(i.filesize))
        wfile.write('<td>{}</td>\n'.format(i.bytestransferred))
        wfile.write('<td>{}</td>\n'.format(i.starttime))
        wfile.write('<td>{}</td>\n'.format(i.endtime))
        wfile.write('<td>{}</td>\n'.format(i.status))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    wfile.close()
    print ("done!")

def create_call_page(call_list, this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating Call page...")

    name = "calls.html"
    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    
    
    #GENERATE CONTENT
    # writes 1st table header "Calls"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Call id</th>\n'.encode('utf-8'))
    wfile.write('<th>Started Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Duration</th>\n'.encode('utf-8'))
    wfile.write('<th>Status</th>\n'.encode('utf-8'))
    wfile.write('<th>Host identiy</th>\n'.encode('utf-8'))
    wfile.write('<th>Call type</th>\n'.encode('utf-8'))
    wfile.write('<th>Remote Host</th>\n'.encode('utf-8'))
    wfile.write('<th>Remote Host displayname</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_call_id" value="Search call id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_started" value="Search started " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_duration" value="Search duration" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_hostIdentiy" value="Search host identity" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_call_type" value="Search call type" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_remoteHost" value="Search remote host " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_remoteHostdisp" value="Search remote host disname" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
    
        
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in call_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.c_id))
        wfile.write('<td>{}</td>\n'.format(i.begin_timestamp))
        wfile.write('<td>{}</td>\n'.format(i.duration))
        wfile.write('<td>{}</td>\n'.format(i.status))
        wfile.write('<td>{}</td>\n'.format(i.host_identity))
        wfile.write('<td><p hidden>{}</p><img src="{}"></td>\n'.format(i.call_type, i.call_type_img))
        wfile.write('<td>{}</td>\n'.format(i.remote_host))
        wfile.write('<td>{}</td>\n'.format(i.remote_host_displayname))
        #wfile.write('<td>LEFT BLANK - MATTIA</td>\n')
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    wfile.close()
    print ("done!")

def create_contact_page(contact_list, this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating Contact page...")
    name = "contacts.html"
    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
        
    
    #GENERATE CONTENT
    # writes 1st table header "Contacts"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Id</th>\n'.encode('utf-8'))
    wfile.write('<th>Avatar</th>\n'.encode('utf-8'))
    wfile.write('<th>Contact Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Display Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Birthday</th>\n'.encode('utf-8'))
    wfile.write('<th>Last Seen Online - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Status</th>\n'.encode('utf-8'))
    wfile.write('<th>Gender</th>\n'.encode('utf-8'))
    wfile.write('<th>City</th>\n'.encode('utf-8'))
    wfile.write('<th>Province</th>\n'.encode('utf-8'))
    wfile.write('<th>Country</th>\n'.encode('utf-8'))
    wfile.write('<th>Home Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Office Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Mobile Phone</th>\n'.encode('utf-8'))
    wfile.write('<th>Email(s)</th>\n'.encode('utf-8'))
    wfile.write('<th>Homepage</th>\n'.encode('utf-8'))
    wfile.write('<th>About</th>\n'.encode('utf-8'))
    wfile.write('<th>Profile Timestamp - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Mood Text</th>\n'.encode('utf-8'))
    wfile.write('<th>Last Used Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Avatar Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_id" value="Search id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_avatar" value="Search avatar" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_contact_name" value="Search contact name" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_display" value="Search diplayname" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_bday" value="Search bday " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_last_seen" value="Search last seen online" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_gender" value="Search gender " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_city" value="Search city" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_province" value="Search province" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_country" value="Search country" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_homePhone" value="Search home phone" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_officePhone" value="Search office phone" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_mobilePhone" value="Search mobile phone" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_email" value="Search emails" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_homepage" value="Search homepage" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_about" value="Search about" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_prof_time" value="Search profile timestamp " class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_mood" value="Search mood" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_lastused" value="Search last used" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_avatar_time" value="Search avatar time" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in contact_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.c_id))
        wfile.write('<td><img src="{}"></td>\n'.format(i.avatar))
        wfile.write('<td>{}</td>\n'.format(i.skypename))
        wfile.write('<td>{}</td>\n'.format(i.displayname))
        wfile.write('<td>{}</td>\n'.format(i.birthday))
        wfile.write('<td>{}</td>\n'.format(i.lastonline_timestamp))
        wfile.write('<td>{}</td>\n'.format(i.final_status))
        wfile.write('<td><p hidden>{}</p><img src="{}"></td>\n'.format(i.gender, i.img))
        wfile.write('<td>{}</td>\n'.format(i.city))
        wfile.write('<td>{}</td>\n'.format(i.province))
        wfile.write('<td>{}</td>\n'.format(i.country))
        wfile.write('<td>{}</td>\n'.format(i.home_phone))
        wfile.write('<td>{}</td>\n'.format(i.office_phone))
        wfile.write('<td>{}</td>\n'.format(i.mobile_phone))
        wfile.write('<td>{}</td>\n'.format(i.emails))
        #wfile.write('<td>LEFT BLANK</td>\n')
        wfile.write('<td>{}</td>\n'.format(i.homepage))
        wfile.write('<td>{}</td>\n'.format(i.about))
        wfile.write('<td>{}</td>\n'.format(i.profile_timestamp))
        wfile.write('<td>{}</td>\n'.format(i.mood_text))
        wfile.write('<td>{}</td>\n'.format(i.lastused_timestamp))
        wfile.write('<td>{}</td>\n'.format(i.avatar_timestamp))

        
        wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))
    wfile.write('</div>\n'.encode('utf-8'))


   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    wfile.close()
    print ("done!")  

def create_chat_page(chat_messages_list, this_report_pages_folder, summary_list, short_list):
    now = date_me()	    
    sys.stdout.write(now+": Creating Chat page...")
    name = "Chat.html"

    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups2)
    wfile.write(popups)
    wfile.write(table_header)
    
    #GENERATE DROP-DOWN LIST
    wfile.write('<form action="">\n'.encode('utf-8'))
    #wfile.write('<select name="chat">\n'.encode('utf-8'))
    wfile.write('<select name="chat" id="chatname">\n'.encode('utf-8'))
    wfile.write('<option value="">All</option>\n'.encode('utf-8'))
    #print len(short_summary)

    length = len(short_list)
    #print short_list
    j = 0
    while j != length:
		#print length, j, short_list[j]
		chat_name = short_list[j]
		total = str(short_list[j+1])
		wfile.write('<option value="{}">{} (total: {})</option>\n'.format(short_list[j], short_list[j], short_list[j+1]))
		j = j+3
    wfile.write('</select>\n'.encode('utf-8'))
    wfile.write('<input id="click" type="button" value="Go">'.encode('utf-8'))
    wfile.write('</form>'.encode('utf-8'))
    
    



    
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Message id</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Sent Time</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Edited</th>\n'.encode('utf-8'))
    wfile.write('<th>Author</th>\n'.encode('utf-8'))
    wfile.write('<th>Message</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Status</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Type</th>\n'.encode('utf-8'))
    wfile.write('<th>Chat Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Dialog partner</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_message id" value="Search message id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_sent" value="Search sent" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_edited" value="Search edited" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_author" value="Search author" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_message" value="Search message" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_type" value="Search type" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_chat_name" id="change" value="Search chat name" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_dialog_partner" value="Search dialog partner" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
        
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in chat_messages_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.m_id))
        wfile.write('<td><p hidden>{}</p>{}</td>\n'.format(i.time_ux, i.timestamp))
        wfile.write('<td>{}</td>\n'.format(i.edited_timestamp))
        wfile.write('<td>{} - ({})</td>\n'.format(i.author, i.from_dispname))
        wfile.write('<td style="word-wrap:break-word">{}</td>\n'.format(i.mess))
        wfile.write('<td>{}</td>\n'.format(i.status))
        wfile.write('<td>{}</td>\n'.format(i.mess_type))
        wfile.write('<td>{}</td>\n'.format(i.chatname))
        wfile.write('<td>{}</td>\n'.format(i.dialog_partner))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    wfile.close()
    print ("done!")

def create_single(name, summary_list, this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating single page for "+name+", Total messages: "+str(len(summary_list))+"...")
###

    wfile = open(this_report_pages_folder+'single_chat/'+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
####
    
            
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Message id</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Sent Time</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Edited</th>\n'.encode('utf-8'))
    wfile.write('<th>Author</th>\n'.encode('utf-8'))
    wfile.write('<th>Message</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Status</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Type</th>\n'.encode('utf-8'))
    wfile.write('<th>Chat Name</th>\n'.encode('utf-8'))
    wfile.write('<th>Dialog partner</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_message id" value="Search message id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_sent" value="Search sent" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_edited" value="Search edited" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_author" value="Search author" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_message" value="Search message" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_type" value="Search type" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_chat_name" id="change" value="Search chat name" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_dialog_partner" value="Search dialog partner" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
        
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in summary_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.m_id))
        wfile.write('<td><p hidden>{}</p>{}</td>\n'.format(i.time_ux, i.timestamp))
        wfile.write('<td>{}</td>\n'.format(i.edited_timestamp))
        wfile.write('<td>{} - ({})</td>\n'.format(i.author, i.from_dispname))
        wfile.write('<td style="word-wrap:break-word; width:100px">{}</td>\n'.format(i.mess))
        wfile.write('<td>{}</td>\n'.format(i.status))
        wfile.write('<td>{}</td>\n'.format(i.mess_type))
        wfile.write('<td>{}</td>\n'.format(i.chatname))
        wfile.write('<td>{}</td>\n'.format(i.dialog_partner))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write('</body></html>\n'.encode('utf-8'))
    
    wfile.close()
    print ("done!")
    statinfo = os.stat(this_report_pages_folder+'single_chat/'+name)
    return statinfo.st_size    
    
def create_chat_summary(summary_list, this_report_pages_folder):
    now = date_me()	    
    
    sys.stdout.write(now+": Creating Chat Summary page...")
    name = "summary_Chat.html"

    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    
    length = len(summary_list)
    wfile.write('<p>This Database contains {} messages. Click <a href="Chat.html">Here</a> to view them all!</p>\n'.format(summary_list[length-1]).encode('utf-8'))    
    
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Chat</th>\n'.encode('utf-8'))
    wfile.write('<th>Participants</th>\n'.encode('utf-8'))
    wfile.write('<th>Total messages</th>\n'.encode('utf-8'))
    wfile.write('<th>From</th>\n'.encode('utf-8'))
    wfile.write('<th>To</th>\n'.encode('utf-8'))
    wfile.write('<th>Size (Kb)</th>\n'.encode('utf-8'))
    wfile.write('<th>Extracted from</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Chat" value="Search Chat" class="search_init" /></th>\n'.encode('utf-8'))
    
    wfile.write('<th><input type="text" name="search_party" value="Search party" class="search_init" /></th>\n'.encode('utf-8'))
    
    wfile.write('<th>{} <a href="Chat.html">View All</a></th>\n'.format(summary_list[length-1]).encode('utf-8'))
    
    wfile.write('<th></th>\n'.encode('utf-8'))
    wfile.write('<th></th>\n'.encode('utf-8'))
    
    size = os.stat(this_report_pages_folder+'Chat.html').st_size
    size = str(round(size/1024.0, 2))+" Kb"
    wfile.write('<th>{}</th>\n'.format(size).encode('utf-8'))
    wfile.write('<th></th>\n'.encode('utf-8'))
        
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content
        
    wfile.write('<tbody>\n'.encode('utf-8'))
    
    i = 0
    while i != length-1:	
        #print i, length  
        wfile.write('<tr>\n'.encode('utf-8'))
        #print summary_list[i+4]
        
        wfile.write('<td>{}    <a href="single_chat/{}">View</a></td>\n'.format(summary_list[i], summary_list[i+4]).encode("utf-8"))
        wfile.write('<td>{}</td>\n'.format(summary_list[i+5]))
        wfile.write('<td>{}</td>\n'.format(summary_list[i+1]))
        wfile.write('<td><p hidden>{}</p>{}</td>\n'.format(summary_list[i+2], parse_date(summary_list[i+2]) ))
        wfile.write('<td><p hidden>{}</p>{}</td>\n'.format(summary_list[i+3], parse_date(summary_list[i+3])))
        wfile.write('<td>{}</td>\n'.format(summary_list[i+7]))
        wfile.write('<td>{}</td>\n'.format(summary_list[i+6]))
        wfile.write('</tr>\n'.encode('utf-8'))
        i = i+8

    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write(footer)
    wfile.close()
    print ("done!")

def create_group_chat_page(group_chat_list, this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating Group Chat page...")
    name = "group.html"

    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Skype Table id</th>\n'.encode('utf-8'))
    wfile.write('<th>Group Chat id</th>\n'.encode('utf-8'))
    wfile.write('<th>Participants</th>\n'.encode('utf-8'))
    wfile.write('<th>Posters</th>\n'.encode('utf-8'))
    wfile.write('<th>Active Members</th>\n'.encode('utf-8'))
    wfile.write('<th>Chat name</th>\n'.encode('utf-8'))
    wfile.write('<th>Start Time - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Last Change - UTC (dd-MM-yyyy)e</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_skype_id" value="Search skype table id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Group_id" value="Search Group chat id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Participants" value="Search Participants" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Posters" value="Search posters" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_active_members" value="Search active members" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_chat_name" value="Search chat name" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_startime" value="Search startime" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_lastchange" value="Search lastchange" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    # writes 1st table content   
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in group_chat_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.c_id))
        wfile.write('<td>{}</td>\n'.format(i.name))
        wfile.write('<td>{}</td>\n'.format(i.participants))
        wfile.write('<td>{}</td>\n'.format(i.posters))
        wfile.write('<td>{}</td>\n'.format(i.active_members))
        wfile.write('<td>{}</td>\n'.format(i.friendlyname))
        wfile.write('<td>{}</td>\n'.format(i.timestamp))
        wfile.write('<td>{}</td>\n'.format(i.last_change))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write(footer)
    wfile.close()
    print ("done!")

def create_voicemail_page(voicemails_list,this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating Voicemail page...")
    name = "voicemails.html"
    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Record</th>\n'.encode('utf-8'))
    wfile.write('<th>Id</th>\n'.encode('utf-8'))
    wfile.write('<th>Partner handle</th>\n'.encode('utf-8'))
    wfile.write('<th>Partner displayname</th>\n'.encode('utf-8'))
    wfile.write('<th>Subject</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Sent - UTC (dd-MM-yyyy)</th>\n'.encode('utf-8'))
    wfile.write('<th>Duration</th>\n'.encode('utf-8'))
    wfile.write('<th>Allowed Duration</th>\n'.encode('utf-8'))
    wfile.write('<th>Size</th>\n'.encode('utf-8'))
    wfile.write('<th>Path</th>\n'.encode('utf-8'))
    wfile.write('<th>Failures</th>\n'.encode('utf-8'))
    wfile.write('<th>Convo id</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_record" value="Search record" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_id" value="Search id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Partner handle" value="Search partner handle" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Partner displayname" value="Search partner displayname" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_subject" value="Search subject" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Message_sent" value="Search sent timestamp" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Duration" value="Search Duration" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Allowed Duration" value="Search Allowed Duration" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Size" value="Search Size" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Path" value="Search Path" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Failures" value="Search Failures" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_Conv_id" value="Search conv id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</tfoot>\n'.encode('utf-8'))
    
    
    # writes 1st table content   
    wfile.write('<tbody>\n'.encode('utf-8'))
    for i in voicemails_list:
        #print i
        wfile.write('<tr>\n'.encode('utf-8'))
        wfile.write('<td>{}</td>\n'.format(i.record))
        wfile.write('<td>{}</td>\n'.format(i.v_id))
        wfile.write('<td>{}</td>\n'.format(i.partner_handle))
        wfile.write('<td>{}</td>\n'.format(i.partner_dispname))
        wfile.write('<td>{}</td>\n'.format(i.subject))
        wfile.write('<td>{}</td>\n'.format(i.timestamp))
        wfile.write('<td>{}</td>\n'.format(i.duration))
        wfile.write('<td>{}</td>\n'.format(i.allowed_duration))
        wfile.write('<td>{}</td>\n'.format(i.size))
        wfile.write('<td>{}</td>\n'.format(i.path))
        wfile.write('<td>{}</td>\n'.format(i.failures))
        wfile.write('<td>{}</td>\n'.format(i.convo_id))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write(footer)
    wfile.close()
    print ("done!")

def create_chat_sync_page(sync_list, this_report_pages_folder):
    now = date_me()	    
    sys.stdout.write(now+": Creating Chatsync page...")
    name = "sync.html"

    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
        
    #GENERATE CONTENT
    # writes 1st table header "Messages"
    wfile.write('<table class="display" id="example" border="1" cellpadding="2" cellspacing="0" >\n'.encode('utf-8'))
    wfile.write('<thead>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th>Conversation</th>\n'.encode('utf-8'))
    wfile.write('<th>Timestamps</th>\n'.encode('utf-8'))
    wfile.write('<th>User</th>\n'.encode('utf-8'))
    wfile.write('<th>Message</th>\n'.encode('utf-8'))
    wfile.write('<th>Status</th>\n'.encode('utf-8'))
    wfile.write('<th>Conversation ID</th>\n'.encode('utf-8'))
    wfile.write('<th>Conversation file</th>\n'.encode('utf-8'))
    wfile.write('<th>Message Hex Check</th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    
    wfile.write('<tfoot>\n'.encode('utf-8'))
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_conversation" value="Search Conversation" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_timestamp" value="Search timestamp" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_user" value="Search user" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_message" value="Search message" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_status" value="Search status" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_conversation_id" value="Search conversation id" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_conversation_file" value="Search conversation file" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('<th><input type="text" name="search_hex_counter" value="Search Hex" class="search_init" /></th>\n'.encode('utf-8'))
    wfile.write('</tr>\n'.encode('utf-8'))
    wfile.write('</thead>\n'.encode('utf-8'))
    
    
    # writes 1st table content   
    wfile.write('<tbody>\n'.encode('utf-8'))
    #print sync_list
    for chat in sync_list:
        #print i
        i = len(chat.messages)
        z = 0
        while z < i:
			
            wfile.write('<tr>\n'.encode('utf-8'))
            wfile.write('<td class="nowrap">{} < > {}</td>\n'.format(chat.messages[z].user1, chat.messages[z].user2))
            
            #print chat.user1, chat.user2, len(chat.messages), chat.messages[0].file_name
            wfile.write('<td class="nowrap">{}</td>\n'.format(chat.messages[z].timestamp))
            wfile.write('<td class="nowrap">{}</td>\n'.format(chat.messages[z].user))
            wfile.write('<td>{}</td>\n'.format(chat.messages[z].line.encode("utf-8")))
            wfile.write('<td>{}</td>\n'.format(chat.messages[z].status))
            wfile.write('<td>{}</td>\n'.format(chat.messages[z].chat_id))
            wfile.write('<td >{}</td>\n'.format(chat.messages[z].file_name))
            wfile.write('<td >{}</td>\n'.format(chat.messages[z].hex_check))
            z = z + 1
            
			
        #wfile.write('<td>{}</td>\n'.format(i.timestamps))
        wfile.write('</tr>\n'.encode('utf-8'))

        
    wfile.write('</tbody>\n'.encode('utf-8'))
    # writes 1st table footer
    wfile.write('</table>\n'.encode('utf-8'))

   


    # writes page footer        
    wfile.write(footer)
    wfile.close()
    print ("done!")

def create_empty_chat_sync_page(sync_list, this_report_pages_folder):
	    
    now = date_me()
    sys.stdout.write(now+": Creating empty Chatsync page...")
    name = "sync.html"

    wfile = open(this_report_pages_folder+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    #GENERATE CONTENT
    wfile.write('<p>The chatsync files were not extracted.</p><br><p> Note: They have to be in the same directory of the main.d as for instance:</p><br><p>- skype/main.db and</p><br><p>- skype/chatsync/folders</p>\n'.encode('utf-8'))    
    wfile.write(footer)
    wfile.close()
    print ("done!")

def create_index_page(this_report_folder, now):
	    
    now = date_me()
    sys.stdout.write(now+": Creating index page...")   
    name = "index.html"
    wfile = open(this_report_folder+"/"+name,'wb')
    header = ""
    header, popups_definit, table_header, footer = generate_header(name)
    wfile.write(header)
    wfile.write(popups_definit)
    wfile.write(table_header)
    
    #Case Table
    wfile.write('<table cellpadding="2" style="text-align:left">'.encode('utf-8'))
    
    #Case Info
    wfile.write('<tr>\n'.encode('utf-8'))
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Case Info: #TODO<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #Date Created
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Date Created: '+now+'<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #Case Number
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Case Number: #TODO<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #Evidence Number
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Evidence Number: #TODO<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #Examiner
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Examiner: #TODO<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #Notes
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>Notes: #TODO<h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    #TODO
    wfile.write('<tr>\n')
    wfile.write('<td>\n'.encode('utf-8'))
    wfile.write('<h2>#TODO: Case info page, db summary page, change javascript function to order dates... <h2>'.encode('utf-8'))
    wfile.write('</td>\n'.encode('utf-8'))
    wfile.write('</tr>\n')
    
    
    wfile.write('</table>\n'.encode('utf-8'))
    
    wfile.write('</br></br>\n'.encode('utf-8'))
    
    wfile.write(footer)
    print ("done!")

###################
# OTHER FUNCTIONS #
###################

def generate_header(page_name):
    PAGES_LV1 = ["sync.html", "Chat Sync", "voicemails.html", "VoiceMails", "group.html", "Group Chat", "summary_Chat.html", "Chat Summary", "Chat.html",\
     "Chat", "index.html", "Index", "accounts.html", "Account", "transfers.html", "Transfers", "calls.html", "Calls", "contacts.html", "Contacts"]
    global popups, popups2, popups3
    plus=""
    minus_dots="../../"
    index_page='../index.html'
    href= 'a href="'
    popups_definit = popups + popups2
    
    if page_name == "index.html":
		
		minus_dots = '../'
		href= 'a href="pages/'
    
    if page_name in PAGES_LV1:
        index = PAGES_LV1.index(page_name)
        
    else:
		index = 8
		minus_dots = '../../../'
		index_page = 'index.html'
		href='a href="../'
		popups_definit = popups2 + popups3
		
    header = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"\n"http://www.w3.org/TR/html4/loose.dtd">\n'\
    '<html><head><title>Skype Xtract - '+PAGES_LV1[index+1]+'</title>\n<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>\n'\
    '<meta name="GENERATOR" title="Skype Xtract - "'+PAGES_LV1[index+1]+' content="Skype Xtract v0.1"/>\n'
    table_header = '</head><body>\n<table cellpadding="10">\n'\
    '<tr>\n<td>\n'\
    '<a href="../index.html"><img src="../../resources/deft_logo.png"/></a></td>\n'\
    '<td >\n<h1>Skype Xtract<h1></td>\n<td >\n'\
    '<h2><a href="accounts.html">Accounts</a><h2></td>\n'\
    '<td >\n<h2><a href="calls.html">Calls</a><h2></td>\n'\
    '<td >\n<h2><a href="summary_Chat.html">Chat Summary</a><h2></td>\n'\
    '<td >\n<h2><a href="contacts.html">Contacts</a><h2></td>\n'\
    '<td >\n<h2><a href="transfers.html">File Transfers</a><h2></td>\n'\
    '<td >\n<h2><a href="group.html">Group Chat</a><h2></td>\n'\
    '<td >\n<h2><a href="voicemails.html">Voice Mails</a><h2></td>\n'\
    '<td >\n<h2><a href="sync.html">Chat Sync</a><h2></td>\n</tr>\n</table>\n</br></br>\n'.replace(page_name, page_name+'" class="current"').replace('a href="',href).replace("../../", minus_dots).replace('../index.html', index_page)
    footer = '</body></html>\n'
       
    return header, popups_definit, table_header, footer
        
#class="current"
	

def check_gender(gender):
		    img = gender
		
		    if gender == 1:
			    img = "../../resources/male.png"
			    gender = "Male"
		    elif gender == 2:
			    img = "../../resources/female.png"
			    gender = "Female"
		    else:
			    img = " "
			    gender = " "	
		    #print img
		    return img, gender	     

#Parse date like 1357674582 into date like this Day-Month-Year Hour:Minute:Second	
	
def parse_date(value):
    if value != 0:
        try:
            #print str(value)
            value = float(value)
            value = datetime.utcfromtimestamp(value)
            #print value
            value = str(value)
            value = datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
            #print value
            value = value.strftime('%d-%m-%Y %H:%M:%S')
            #print str(value)
        except TypeError:
            value = " "
    else:
		value = " "        
    return value

def sync_users(chat_messages_list, sync_list):
	
	#This function should find a link between messages in chat sync and chats and
	#return the correct user when possible.
	
	#GET all the user id from the chat sync
    sync_user_list = []
    for chat in sync_list:
        i = len(chat.messages)
        z = 0
        while z < i:
			
            if chat.messages[z].user not in sync_user_list:
                message = chat.messages[z].line
                how_many = 0
                for m in chat_messages_list:
                    original_mess = m.mess
                    if '<a href="' in original_mess and '</a>' in original_mess: 
                        #print("si che ci sono")
                        original_mess = re.sub('<[^>]+>', '', original_mess)    	
                    #if "http://www.basi" in message and "http://www.basi" in original_mess:
					#	print ("this is message: " +message)
					#	print ("this is m.mess: "+ original_mess)
                    if message == original_mess:
                        how_many = how_many + 1
                        user = m.author
                #print how_many
                if how_many == 1:
                    sync_user_list.append(chat.messages[z].user)
                    sync_user_list.append(user)
                #else:
					#print chat.messages[z].user   
            
				
            z = z +1
    #print sync_user_list, len(sync_user_list)
    u = 0
    #print sync_user_list[u]
    #print sync_user_list[u+1]
    while u < len(sync_user_list):
        for chat in sync_list:
            i = len(chat.messages)
            z = 0
            #print("sono qui")
            while z < i:
                if chat.messages[z].user == sync_user_list[u]:
                    #print ("Questo "+ chat.messages[z].user+" e' uguale a questo: "+ sync_user_list[u+1])
                    chat.messages[z].user = sync_user_list[u+1]
                z = z +1    
				
        u = u +2
    return sync_list        	
def sync_edit(chat_messages_list, sync_list):
	
	#This function change the status to "Edit" to the messages that has been edited.
	#Find the timestamps of edited chat messages.
	#Find the same timestamp and message in the chat sync list and change its status to edited.
    for m in chat_messages_list:
        edited_time = m.edited_timestamp
        if edited_time != "":
            for chat in sync_list:
                i = len(chat.messages)
                z = 0
                while z < i:
					
			        #DELETED THIS PART: chat.messages[z].status == "Edit" and
			        #Does it affect the edit function? TEST. 
                    if chat.messages[z].timestamp == edited_time:
                        chat.messages[z].status = "Edit"
                    z = z +1		
            
    #This function change the status to "Edit" to the original messages that has been edited.
	#From the chat sync it is possible to understand the edited message but the original
	#message will result as a standard message.
	#With this function, you look for the edited message and set the status to "edited" for
	#the previous message in time by the same user.
	#Note:
	#if there are more then one edited messages for the same message this function is not able to find
	#those messages unless they were already found during the parsing process.
    for chat in sync_list:
        i = len(chat.messages)
        z = 0
        while z < i:
			
            if chat.messages[z].status == "Edit":
                if chat.messages[z-1].user == chat.messages[z].user:
                    chat.messages[z-1].status = "Edit"
                elif chat.messages[z-2].user == chat.messages[z].user:
                    chat.messages[z-2].status = "Edit"	
                elif chat.messages[z-3].user == chat.messages[z].user:
                    chat.messages[z-3].status = "Edit"	
				
            z = z +1    
    return sync_list        	
    	
def date_me():
    now = datetime.utcnow()
    try:
        now = datetime.strptime(str(now), '%Y-%m-%d %H:%M:%S')
    except:
        now = datetime.strptime(str(now), '%Y-%m-%d %H:%M:%S.%f')
    try:    
        now = now.strftime('%d-%m-%Y %H.%M.%S')
    except:
        now = now.strftime('%d-%m-%Y %H.%M.%S.%f')    
    return now
	
#############
# CONSTANTS
#############

HTML_FOLD = "Skypextractor_report_"
INSTALLATION_DIR = os.path.realpath(__file__) # This is where the executable is stored. 
INSTALLATION_DIR = INSTALLATION_DIR.replace("skype.py","")
#print INSTALLATION_DIR
 
###############################
# Call All the Functions      
# to generate the HTML REPORT 
###############################
class Main(argparse.Action):
     def __call__(self, parser, namespace, values, option_string=None):
         
         file_in = values
         
         # Have you specified an output directory?
         if namespace.output_dir:
             global HTML_FOLD
             HTML_FOLD = namespace.output_dir+ HTML_FOLD		 

         # Get the date and format it as DAY-MONTH-YEAR HOURS-MINUTES-SECONDS
         now = date_me()        
         
         #Create directory tree (root + pages + avatar)
         this_report_root_folder = str(HTML_FOLD)+str(now).replace(" ", "_")
         this_report_pages_folder = this_report_root_folder+"/pages/"
         
         global this_report_complete_tree
         this_report_complete_tree = this_report_pages_folder+"/avatar/"
         this_report_complete_tree2 = this_report_pages_folder+"/single_chat/"
         
         os.makedirs(this_report_complete_tree)
         os.makedirs(this_report_complete_tree2)
         
         # If you have specified a new output folder, you need to copy the resources files in the right place,
         # otherwise you won't have all the cool images and javascript functions! 
         if namespace.output_dir:
             global INSTALLATION_DIR
             copy_this = INSTALLATION_DIR+"resources/"
             to_this = namespace.output_dir+"/resources/"
             if os.path.exists(to_this):
                 print("The resources directory already exists in this path: "+to_this+" , not copying it again.")
             else:
                 shutil.copytree(copy_this,to_this)

         
         #########################
         
         #########################
         # Start creating/populating the pages with content..
         #########################
         
         
         #Create index page
         create_index_page(this_report_root_folder, now)
         
         #Create the contacts list parsing the sqlite3 main.db
         contact_list = get_contacts(file_in)
         #pass the list just created to create_contact_page to create its report page.
         create_contact_page(contact_list, this_report_pages_folder)
         
         account_list = get_accounts(file_in)
         create_accounts_page(account_list, this_report_pages_folder)
         
         call_list = get_calls(file_in)
         create_call_page(call_list, this_report_pages_folder)
         
         chat_messages_list = get_chat_messages(file_in)
         summary_list, short_list = get_chat_summary(chat_messages_list, this_report_pages_folder, file_in)  #, short_summary
         create_chat_page(chat_messages_list, this_report_pages_folder, summary_list, short_list)
         create_chat_summary(summary_list, this_report_pages_folder)
         
         transfers_list = get_transfers(file_in)
         create_transfer_page(transfers_list, this_report_pages_folder)
         
         group_chat_list = get_group_chat(file_in)
         create_group_chat_page(group_chat_list, this_report_pages_folder)
         
         
         
         voicemails_list = get_voicemails(file_in)
         create_voicemail_page(voicemails_list, this_report_pages_folder)
         
         ############
         # CHATSYNC #
         ############
         if namespace.chatsync:
             dirname, filename = os.path.split(os.path.abspath(file_in))
             print dirname, filename
             
             if namespace.debug:
                  this_report_debug_folder = this_report_root_folder+"/debug/"
                  os.makedirs(this_report_debug_folder)
                  debug = True
                  sync.set_debug(debug, this_report_debug_folder)
             else:
                  debug = False
                  sync.set_debug(debug, "")     

         
             #Check if there is a chatsync folder in the same folder of main.db
             #If there is one, you can extract the chatsync...
             chatsync_dir = dirname + "/chatsync"
             if os.path.exists(chatsync_dir):
                 print ("Chatsync folder found...")
                 sync_list = sync.check_sync(chatsync_dir)
                 sync_list = sync_users(chat_messages_list, sync_list)
                 sync_list = sync_edit(chat_messages_list, sync_list)
                 create_chat_sync_page(sync_list, this_report_pages_folder)
             else:
			     print ("No chatsync folder found in the current path: "+dirname)
			     sync_list = ["hello"]
			     create_empty_chat_sync_page(sync_list, this_report_pages_folder)
         
         
         outfile = str(this_report_root_folder)+"/index.html"
         webbrowser.open(outfile)
         #sync_users(chat_messages_list, sync_list)

         if namespace.csv:
			print("Extracting in CSV format...")
			this_report_csv_folder = this_report_root_folder+"/csv/"
			os.makedirs(this_report_csv_folder)
			#Csv(file_in, this_report_csv_folder)
			Csv(file_in, this_report_csv_folder)
        
global popups, popups2

popups2 = """
<style type="text/css">
body {
    font-family: calibri;
    background-color: #f5f5f5;
    font-size:0.9em;

}
h1 {
    font-family: courier;
    font-style:italic;
    color: #444444;
    font-size:0.9em;

}
h2 {
    font-style:italic;
    color: #444444;
    font-size:0.9em;
}
h3 {
    font-style:italic;
}
table {
    text-align: left;
    font-size:0.9em;
}
th {
    font-style:italic;
    white-space:nowrap

}

td.nowrap {
    white-space:nowrap   
}

td.text {
    width: 200px;
    font-size:0.9em;
    text-align: left;
    
}
td.contact {
    width: 250px;
    font-size:0.9em;

}
tr.even {
    background-color: #DDDDDD
    font-size:0.9em;

}
tr.me {
    background-color: #88FF88;
    font-size:0.9em;

}
tr.other {
    background-color: #F5F5F5;
    font-size:0.9em;

}
tr.newgroupname {
    background-color: #FFCC33;
    font-size:0.9em;

}

a{
color: #0099FF;
}
.current{
 color: #FFBF00;
 font-style: italic bold;
 
}
</style>

"""
popups = """

<style type="text/css" title="currentStyle">
			@import "../../resources/DataTables-1.9.4/media/css/demo_page.css"; 
			@import "../../resources/DataTables-1.9.4/media/css/demo_table.css";
		</style>
<script type="text/javascript" language="javascript" src="../../resources/DataTables-1.9.4/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="../../resources/DataTables-1.9.4/media/js/jquery.dataTables.js"></script>
<script type="text/javascript">
var asInitVals = new Array();

$(document).ready(function() {
	var oTable = $('#example').dataTable( {
		"oLanguage": {
			"sSearch": "Search all columns:"
		}
	} );
	$("#click").click(function(){
    
    oTable.fnFilter( $("#chatname").val() );
    });
    
	$("tfoot input").keyup( function () {
		/* Filter on the column (the index) of this element */
		oTable.fnFilter( this.value, $("tfoot input").index(this) );
	} );
	
	
	
	/*
	 * Support functions to provide a little bit of 'user friendlyness' to the textboxes in 
	 * the footer
	 */
	$("tfoot input").each( function (i) {
		asInitVals[i] = this.value;
	} );
	
	$("tfoot input").focus( function () {
		if ( this.className == "search_init" )
		{
			this.className = "";
			this.value = "";
		}
	} );
	
	$("tfoot input").blur( function (i) {
		if ( this.value == "" )
		{
			this.className = "search_init";
			this.value = asInitVals[$("tfoot input").index(this)];
		}
	} );
} );</script>



 """
popups3 = """

<style type="text/css" title="currentStyle">
			@import "../../../resources/DataTables-1.9.4/media/css/demo_page.css"; 
			@import "../../../resources/DataTables-1.9.4/media/css/demo_table.css";
		</style>
<script type="text/javascript" language="javascript" src="../../../resources/DataTables-1.9.4/media/js/jquery.js"></script>
<script type="text/javascript" language="javascript" src="../../../resources/DataTables-1.9.4/media/js/jquery.dataTables.js"></script>
<script type="text/javascript">
var asInitVals = new Array();

$(document).ready(function() {
	var oTable = $('#example').dataTable( {
		"oLanguage": {
			"sSearch": "Search all columns:"
		}
	} );
	$("#click").click(function(){
    
    oTable.fnFilter( $("#chatname").val() );
    });
    
	$("tfoot input").keyup( function () {
		/* Filter on the column (the index) of this element */
		oTable.fnFilter( this.value, $("tfoot input").index(this) );
	} );
	
	
	
	/*
	 * Support functions to provide a little bit of 'user friendlyness' to the textboxes in 
	 * the footer
	 */
	$("tfoot input").each( function (i) {
		asInitVals[i] = this.value;
	} );
	
	$("tfoot input").focus( function () {
		if ( this.className == "search_init" )
		{
			this.className = "";
			this.value = "";
		}
	} );
	
	$("tfoot input").blur( function (i) {
		if ( this.value == "" )
		{
			this.className = "search_init";
			this.value = asInitVals[$("tfoot input").index(this)];
		}
	} );
} );</script>



 """


parser = argparse.ArgumentParser(description="Skype Xtractor v 0.1.8.8 Beta - DEFT 8: Extract Skype's tables from the Skype main.db and chatsync files.", epilog="Skype Xtractor is an open source tool written for DEFT 8 under the GNU GPLv3 license. If you have any trouble or if you find a bug please report it on DEFT forum at http://www.deftlinux.net/forum/ or write an email to the developer at nico@deftlinux.net")
parser.add_argument("File", action=Main, help="extract from main.db the Skype chats in HTML format.")
parser.add_argument("-C", "--chatsync",action="store_true", help="extract chatsync files in HTML format (deleted and modified messages). Note: The chatsync folder has to be in the same directory of the main.db to be extracted.")
parser.add_argument("-c", "--csv",action="store_true", help="extract the main.db in HTML+CSV format")
parser.add_argument("-o","--output-dir", help="extract the files in this directory! If the directory doesn't exist, it is created.")
parser.add_argument("-d", "--debug",action="store_true", help="save debugging information into the debug folder for each chatsync")


args = parser.parse_args()
