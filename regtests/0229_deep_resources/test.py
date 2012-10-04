from test_support import *
import os

def create_res(name,content):
    f=open(name,'w')
    f.write(content)
    f.close();

os.mkdir('rout')

D='dir1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
SD=D + '/' + 'sdir_yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
SSD=SD + '/' + 'ssdir_zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'

os.mkdir(D)
os.mkdir(SD)
os.mkdir(SSD)

create_res(D + '/text1.txt', 'text 1')
create_res(D + '/text2.txt', 'text 2')
create_res(SD + '/text3.txt', 'text 3')
create_res(SD + '/text4.txt', 'text 4')
create_res(SSD + '/text5-DEMO.txt', 'text 5')
create_res(SSD + '/N-text6.txt', 'text 6')

exec_cmd('awsres',
         ['-q', '-r', 'rdemo', '-R', '-o', 'rout', D])

build_and_run('deep_res');
