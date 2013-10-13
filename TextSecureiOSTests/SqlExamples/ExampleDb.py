#databases
import re
import os
class Database(object):
	def __init__(self,strings,create,indexs):
		self.strings=strings
		self.create=create
		self.indexs=indexs
		
	def pythonify_strings(self):
		"""pythonify changes code into python code
		"""
		lst=self.strings.split('\n')
		return '\n'.join([s.replace('static final String','').replace(';','').replace('public ','').replace('private ','').strip() for s in lst])
	def pythonify_create(self):
		return self.create.replace('\n','')
	def pythonify_indexs(self):
		pass

	def objectivecify(self):
		"""changes code into objectivec"""
		pass
		
	def sqlify(self):
		"""changes code into SQL"""
		variables=self.pythonify_strings()
		exec(variables)
		
		create_code=self.pythonify_create()
		exec('create_sql='+create_code)
		sql=[create_sql]
		for idx in self.indexs:
			exec('idx_sql='+idx)
			sql+=[idx_sql]
		return '\n'.join(sql)
		
###
# DraftDatabase.java
###
draftdb_strings='''private static final String TABLE_NAME  = "drafts";
public  static final String ID          = "_id";
public  static final String THREAD_ID   = "thread_id";
public  static final String DRAFT_TYPE  = "type";
public  static final String DRAFT_VALUE = "value";'''

draftdb_create='''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, " + THREAD_ID + " INTEGER, " + DRAFT_TYPE + " TEXT, " + DRAFT_VALUE + " TEXT);"'''

draftdb_indexs=[
''' "CREATE INDEX IF NOT EXISTS draft_thread_index ON " + TABLE_NAME + " (" + THREAD_ID + ");"'''
]

draftdb=Database(draftdb_strings,draftdb_create,draftdb_indexs)

###
# IdentityDatabase.java
###
identdb_strings = '''private static final String TABLE_NAME    = "identities";
private static final String ID            = "_id";
public  static final String IDENTITY_KEY  = "key";
public  static final String IDENTITY_NAME = "name";
public  static final String MAC           = "mac";'''
identdb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, " +
  IDENTITY_KEY + " TEXT UNIQUE, " + IDENTITY_NAME + " TEXT UNIQUE, "  +
  MAC + " TEXT);"'''
identdb_indexs=[
]

identdb=Database(identdb_strings,identdb_create,identdb_indexs)

###
# MmsAddressDatabase.java
###
mmsaddressdb_strings = '''private static final String TABLE_NAME      = "mms_addresses";
private static final String ID              = "_id";
private static final String MMS_ID          = "mms_id";
private static final String TYPE            = "type";
private static final String ADDRESS         = "address";
private static final String ADDRESS_CHARSET = "address_charset";'''
mmsaddressdb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, " +
  MMS_ID + " INTEGER, " +  TYPE + " INTEGER, " + ADDRESS + " TEXT, " +
  ADDRESS_CHARSET + " INTEGER);"'''
mmsaddressdb_indexs=[
'''"CREATE INDEX IF NOT EXISTS mms_addresses_mms_id_index ON " + TABLE_NAME + " (" + MMS_ID + ");"'''
]
mmsaddressdb=Database(mmsaddressdb_strings, mmsaddressdb_create,mmsaddressdb_indexs)

###
# MmsDatabase.java
###
mmsdb_strings =  '''public  static final String TABLE_NAME         = "mms";
public  static final String ID                 = "_id";
private static final String THREAD_ID          = "thread_id";
public  static final String DATE_SENT          = "date";
public  static final String DATE_RECEIVED      = "date_received";
public  static final String MESSAGE_BOX        = "msg_box";
private static final String READ               = "read";
private static final String MESSAGE_ID         = "m_id";
private static final String SUBJECT            = "sub";
private static final String SUBJECT_CHARSET    = "sub_cs";
private static final String CONTENT_TYPE       = "ct_t";
private static final String CONTENT_LOCATION   = "ct_l";
private static final String EXPIRY             = "exp";
private static final String MESSAGE_CLASS      = "m_cls";
public  static final String MESSAGE_TYPE       = "m_type";
private static final String MMS_VERSION        = "v";
private static final String MESSAGE_SIZE       = "m_size";
private static final String PRIORITY           = "pri";
private static final String READ_REPORT        = "rr";
private static final String REPORT_ALLOWED     = "rpt_a";
private static final String RESPONSE_STATUS    = "resp_st";
private static final String STATUS             = "st";
private static final String TRANSACTION_ID     = "tr_id";
private static final String RETRIEVE_STATUS    = "retr_st";
private static final String RETRIEVE_TEXT      = "retr_txt";
private static final String RETRIEVE_TEXT_CS   = "retr_txt_cs";
private static final String READ_STATUS        = "read_status";
private static final String CONTENT_CLASS      = "ct_cls";
private static final String RESPONSE_TEXT      = "resp_txt";
private static final String DELIVERY_TIME      = "d_tm";
private static final String DELIVERY_REPORT    = "d_rpt";'''
mmsdb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, "                          +
  THREAD_ID + " INTEGER, " + DATE_SENT + " INTEGER, " + DATE_RECEIVED + " INTEGER, " + MESSAGE_BOX + " INTEGER, " +
  READ + " INTEGER DEFAULT 0, " + MESSAGE_ID + " TEXT, " + SUBJECT + " TEXT, "                +
  SUBJECT_CHARSET + " INTEGER, " + CONTENT_TYPE + " TEXT, " + CONTENT_LOCATION + " TEXT, "    +
  EXPIRY + " INTEGER, " + MESSAGE_CLASS + " TEXT, " + MESSAGE_TYPE + " INTEGER, "             +
  MMS_VERSION + " INTEGER, " + MESSAGE_SIZE + " INTEGER, " + PRIORITY + " INTEGER, "          +
  READ_REPORT + " INTEGER, " + REPORT_ALLOWED + " INTEGER, " + RESPONSE_STATUS + " INTEGER, " +
  STATUS + " INTEGER, " + TRANSACTION_ID + " TEXT, " + RETRIEVE_STATUS + " INTEGER, "         +
  RETRIEVE_TEXT + " TEXT, " + RETRIEVE_TEXT_CS + " INTEGER, " + READ_STATUS + " INTEGER, "    +
  CONTENT_CLASS + " INTEGER, " + RESPONSE_TEXT + " TEXT, " + DELIVERY_TIME + " INTEGER, "     +
  DELIVERY_REPORT + " INTEGER);"'''
mmsdb_indexs=[
 '''"CREATE INDEX IF NOT EXISTS mms_thread_id_index ON " + TABLE_NAME + " (" + THREAD_ID + ");"''',
 '''"CREATE INDEX IF NOT EXISTS mms_read_index ON " + TABLE_NAME + " (" + READ + ");"''',
 '''"CREATE INDEX IF NOT EXISTS mms_read_and_thread_id_index ON " + TABLE_NAME + "(" + READ + "," + THREAD_ID + ");"''',
 '''"CREATE INDEX IF NOT EXISTS mms_message_box_index ON " + TABLE_NAME + " (" + MESSAGE_BOX + ");"'''
]
mmsdb=Database(mmsdb_strings,mmsdb_create,mmsdb_indexs)

###
# PartDatabase.java
###
partdb_strings = '''private static final String TABLE_NAME          = "part";
private static final String ID                  = "_id";
private static final String MMS_ID              = "mid";
private static final String SEQUENCE            = "seq";
private static final String CONTENT_TYPE        = "ct";
private static final String NAME                = "name";
private static final String CHARSET             = "chset";
private static final String CONTENT_DISPOSITION = "cd";
private static final String FILENAME            = "fn";
private static final String CONTENT_ID          = "cid";
private static final String CONTENT_LOCATION    = "cl";
private static final String CONTENT_TYPE_START  = "ctt_s";
private static final String CONTENT_TYPE_TYPE   = "ctt_t";
private static final String ENCRYPTED           = "encrypted";
private static final String DATA                = "_data";'''
partdb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, "              +
  MMS_ID + " INTEGER, " + SEQUENCE + " INTEGER DEFAULT 0, "                       +
  CONTENT_TYPE + " TEXT, " + NAME + " TEXT, " + CHARSET + " INTEGER, "            +
  CONTENT_DISPOSITION + " TEXT, " + FILENAME + " TEXT, " + CONTENT_ID + " TEXT, " +
  CONTENT_LOCATION + " TEXT, " + CONTENT_TYPE_START + " INTEGER, "                +
  CONTENT_TYPE_TYPE + " TEXT, " + ENCRYPTED + " INTEGER, " + DATA + " TEXT);"'''
partdb_indexs=[
'''"CREATE INDEX IF NOT EXISTS part_mms_id_index ON " + TABLE_NAME + " (" + MMS_ID + ");"'''
]
partdb=Database(partdb_strings,partdb_create,partdb_indexs)

###
# SmsDatabase.java
###
smsdb_strings = '''public  static final String TABLE_NAME         = "sms";
public  static final String ID                 = "_id";
public  static final String THREAD_ID          = "thread_id";
public  static final String ADDRESS            = "address";
public  static final String PERSON             = "person";
public  static final String DATE_RECEIVED      = "date";
public  static final String DATE_SENT          = "date_sent";
public  static final String PROTOCOL           = "protocol";
public  static final String READ               = "read";
public  static final String STATUS             = "status";
public  static final String TYPE               = "type";
public  static final String REPLY_PATH_PRESENT = "reply_path_present";
public  static final String SUBJECT            = "subject";
public  static final String BODY               = "body";
public  static final String SERVICE_CENTER     = "service_center";'''
smsdb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " integer PRIMARY KEY, "                +
  THREAD_ID + " INTEGER, " + ADDRESS + " TEXT, " + PERSON + " INTEGER, " + DATE_RECEIVED  + " INTEGER, " +
  DATE_SENT + " INTEGER, " + PROTOCOL + " INTEGER, " + READ + " INTEGER DEFAULT 0, " +
  STATUS + " INTEGER DEFAULT -1," + TYPE + " INTEGER, " + REPLY_PATH_PRESENT + " INTEGER, " +
  SUBJECT + " TEXT, " + BODY + " TEXT, " + SERVICE_CENTER + " TEXT);"'''
smsdb_indexs = [
'''"CREATE INDEX IF NOT EXISTS sms_thread_id_index ON " + TABLE_NAME + " (" + THREAD_ID + ");"''',
'''"CREATE INDEX IF NOT EXISTS sms_read_index ON " + TABLE_NAME + " (" + READ + ");"''',
'''"CREATE INDEX IF NOT EXISTS sms_read_and_thread_id_index ON " + TABLE_NAME + "(" + READ + "," + THREAD_ID + ");"''',
'''"CREATE INDEX IF NOT EXISTS sms_type_index ON " + TABLE_NAME + " (" + TYPE + ");"'''
]
smsdb=Database(smsdb_strings,smsdb_create,smsdb_indexs)

##
# ThreadDatabase.java
##
threaddb_strings = '''private static final String TABLE_NAME          = "thread";
public  static final String ID                  = "_id";
public  static final String DATE                = "date";
public  static final String MESSAGE_COUNT       = "message_count";
public  static final String RECIPIENT_IDS       = "recipient_ids";
public  static final String SNIPPET             = "snippet";
private static final String SNIPPET_CHARSET     = "snippet_cs";
public  static final String READ                = "read";
private static final String TYPE                = "type";
private static final String ERROR               = "error";
private static final String HAS_ATTACHMENT      = "has_attachment";'''
threaddb_create = '''"CREATE TABLE " + TABLE_NAME + " (" + ID + " INTEGER PRIMARY KEY, "                             +
  DATE + " INTEGER DEFAULT 0, " + MESSAGE_COUNT + " INTEGER DEFAULT 0, "                         +
  RECIPIENT_IDS + " TEXT, " + SNIPPET + " TEXT, " + SNIPPET_CHARSET + " INTEGER DEFAULT 0, "     +
  READ + " INTEGER DEFAULT 1, " + TYPE + " INTEGER DEFAULT 0, " + ERROR + " INTEGER DEFAULT 0, " +
  HAS_ATTACHMENT + " INTEGER DEFAULT 0);"'''
threaddb_indexs=[
'''"CREATE INDEX IF NOT EXISTS thread_recipient_ids_index ON " + TABLE_NAME + " (" + RECIPIENT_IDS + ");"'''
]
threaddb=Database(threaddb_strings,threaddb_create,threaddb_indexs)


if __name__ == '__main__':
	databases_to_port = [draftdb,
	identdb,
	mmsdb,
	partdb,
	smsdb,
	threaddb,
	mmsaddressdb]
	for db in databases_to_port:
			print db.sqlify()
	
	#either generate Objective-C  to generate SQL statements or sql statements directly
	
	
	
	
	