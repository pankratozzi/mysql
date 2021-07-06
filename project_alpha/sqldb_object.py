import mysql.connector
from mysql.connector import Error
import sys
import time


class MySQLJob:

    def __init__(self, host='localhost', user='root', passwd='getontop', db='naive_movie_service'):
        self.__host = host
        self.__user = user
        self.__password = passwd
        self.__db = db

    def __connect(self):
        try:
            self.__conn = mysql.connector.connect(host=self.__host, user=self.__user,
                                                  passwd=self.__password, db=self.__db)
            self.__cursor = self.__conn.cursor()
        except Error as err:
            sys.stderr.write(f'{err.errno}: {err.msg}')
        else:
            sys.stdout.write('Connected successfully.')

    def __shutdown(self):
        self.__conn.close()

    def __str__(self):
        self.__connect()
        self.__cursor.execute('SHOW TABLES')
        output = self.__cursor.fetchall()
        output = [elem[0] for elem in output]
        self.__shutdown()
        return '; '.join(output)

    def execute(self, query: str, values=None):
        self.__connect()
        try:
            if values:
                self.__cursor.execute(query, values)
            else:
                self.__cursor.execute(query)
            if ('INSERT' in query or 'UPDATE' in query or 'DELETE' in query):
                self.__conn.commit()
        except Error as err:
            sys.stderr.write(f'{err.errno}: {err.msg}')
        else:
            sys.stdout.write(f'SQL request commited.\n')
            return self.__cursor.fetchall()
        finally:
            if self.__conn.is_connected():
                self.__shutdown()

    def __len__(self):
        try:
            self.__connect()
            table = input('Enter table name: ')
            query = f'SELECT COUNT(*) FROM {table}'
            self.__cursor.execute(query)
            result = self.__cursor.fetchone()
            self.__shutdown()
            return result[0]
        except Error as err:
            sys.stderr.write(f'{err.errno}: {err.msg}')

    def __getitem__(self, index):
        table = input('Enter table name: ')
        try:
            query = f'SELECT * FROM {table} WHERE id = {index}'
            result = self.execute(query)
            return result
        except Error as err:
            sys.stderr.write(f'{err.errno}: {err.msg}')

    def __call__(self, pr_name: str, *args, **kwargs):
        self.__connect()
        print(args)
        self.__cursor.callproc(pr_name, list(args))
        stored = [x.fetchone() for x in self.__cursor.stored_results()]
        self.__shutdown()
        return stored

    def select(self, table, *args, where=None, **kwargs):
        query = 'SELECT '
        num_values = len(args) - 1
        for i, arg in enumerate(args):
            query += '`' + arg + '`'
            if i < num_values:
                query += ', '
        query += f'FROM {table}'
        if kwargs:
            query += ' WHERE '
            for i, (k, v) in enumerate(kwargs.items()):
                query += f'{k}={v} AND ' if i < len(kwargs.items()) - 1 else f'{k}={v}'
        elif where is not None:
            query += f' WHERE {where}'
        return self.execute(query), self.__cursor.rowcount

    def insert(self, table, *args, **kwargs):
        start_time = time.time()
        values = None
        query = f'INSERT INTO {table} '
        if args:
            values = args
            query += 'VALUES (' + ', '.join(['%s']*len(args)) + ')'
        elif kwargs:
            values = tuple(kwargs.values())
            query += '(' + ', '.join(['`%s`']*len(kwargs.keys())) % tuple(kwargs.keys()) + \
                     ') VALUES (' + ', '.join(['%s']*len(kwargs.values())) + ')'
        self.execute(query, values)
        end_time = time.time()
        return f'{self.__cursor.rowcount} row affected: {end_time - start_time:.4f}s'

    def update(self, table, where=None, **kwargs):
        start_time = time.time()
        query = f'UPDATE {table} SET '
        keys, values = tuple(kwargs.keys()), tuple(kwargs.values())
        num_values = len(keys) - 1
        for i, key in enumerate(keys):
            query += f'`{key}` = %s'
            if i < num_values:
                query += ', '
        query += f' WHERE {where}'
        self.execute(query, values)
        end_time = time.time()
        return f'{self.__cursor.rowcount} row affected: {end_time - start_time:.4f}s'

    def delete(self, table, where=None):
        start_time = time.time()
        query = f'DELETE FROM {table}'
        if where:
            query += f' WHERE {where}'
        self.execute(query)
        end_time = time.time()
        return f'{self.__cursor.rowcount} row affected: {end_time - start_time:.4f}s'


if __name__ == '__main__':
    worker = MySQLJob()
    print(worker)
    print(len(worker))
    res = worker('sp_recommendationV2', 5, 5)
    print(res, worker('sp_help_msg', 2))
    print(worker[40])
    result = worker.select('users', 'id', 'email', 'phone', id=5, phone='17917028347')
    print(*result)
    result = worker.select('users', 'id', 'email', 'phone', where='id BETWEEN 2 AND 5')
    print(*result)
    res = worker.insert('users', '123', 'mail1@mailer.org', 'NULL', '79167318083', '2021-07-07',
                        '2021-07-07')
    print(res)
    res = worker.insert('users', email='mail2@ailer.com', phone='79235557681')
    print(res)
    res = worker.update('users', where='id = 124', email='ssa@mmm.com')
    print(res)
    worker.delete('users', where='id = 123')
    res = worker.delete('users', where='id = 124')
    print(res)
