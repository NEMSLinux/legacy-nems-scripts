#!/usr/bin/python
#
# Sample program for accessing the Livestatus Module
# from a python program
socket_path = "/usr/local/nagios/var/rw/live.sock"

import socket
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(socket_path)

# Write command to socket
s.send("GET hosts\n")

# Important: Close sending direction. That way
# the other side knows we are finished.
s.shutdown(socket.SHUT_WR)

# Now read the answer
answer = s.recv(100000000)

# Parse the answer into a table (a list of lists)
table = [ line.split(';') for line in answer.split('\n')[:-1] ]

print table
