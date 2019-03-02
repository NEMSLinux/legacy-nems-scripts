#!/usr/bin/python
import sys

def main():

  if len(sys.argv)<3:
    socket_path = "/usr/local/nagios/var/rw/live.sock"
    query = "hosts"
  else:
    socket_path = str(sys.argv[1])
    query = str(sys.argv[2])

  import socket
  s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
  s.connect(socket_path)

  # Write command to socket
  s.send("GET " + query + "\n")

  # Important: Close sending direction. That way
  # the other side knows we are finished.
  s.shutdown(socket.SHUT_WR)

  # Now read the answer
  answer = s.recv(100000000)

  result = answer.count('\n')
  print result

  # Parse the answer into a table (a list of lists)
#  table = [ line.split(';') for line in answer.split('\n')[:-1] ]
#  print table

if __name__ == '__main__':
  main()
