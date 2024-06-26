import pymssql

conn = pymssql.connect(server='ZY-SURFACE')

# create a cursor to run queries
cursor = conn.cursor()
cursor.execute('SELECT * FROM INFORMATION_SCHEMA.TABLES')
rows = cursor.fetchall()
[print(rows) for row in rows]


# If we are updating/making any changes
# conn.commit()