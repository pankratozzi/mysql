from mysql.connector import Error
import mysql.connector
from random import shuffle
from itertools import product
import sys
import argparse
from tqdm import tqdm
import time


parser = argparse.ArgumentParser()
parser.add_argument('-r', '--rows', default=300, help='number of rows to insert 1..432')
args = vars(parser.parse_args())
num_rows = int(args['rows'])

my_list = [(x, y, j, i) for (x, y, j, i) in product(range(1, 201, 35), range(1, 41, 12),
                                                            range(1, 81, 15), range(1, 20, 7))]
shuffle(my_list)
# print(*my_list[:5], len(my_list))

conn = mysql.connector.connect(host='localhost', user='root', passwd='getontop',
                               db='naive_movie_service')
cursor = conn.cursor()
# cursor.execute('SELECT * FROM movie_title LIMIT 3')
# for row in cursor.fetchall():
#    print(row)
cursor.execute('SELECT id FROM movie_title ORDER BY id DESC LIMIT 1')
last_id = cursor.fetchall()[0][0]
for i in tqdm(range(num_rows), total=num_rows):
    cursor.execute('INSERT INTO movie_title (id, media_id, producer_id, actor_id, studio_id)'
                   'VALUES (%s, %s, %s, %s, %s)', ((last_id + i + 1), my_list[i][0], my_list[i][1],
                                           my_list[i][2], my_list[i][3]))
    time.sleep(0.05)
cursor.execute('SELECT COUNT(*) FROM movie_title')
sys.stderr.write(str(cursor.fetchall()[0][0]) + 'rows total')
conn.commit()
conn.close()
