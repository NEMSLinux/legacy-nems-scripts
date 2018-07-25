#!/usr/bin/python
import sys, getopt

def main(argv):
   socket_path = "/usr/local/nagios/var/rw/live.sock"
   try:
      opts, args = getopt.getopt(argv,"hs:",["socket="])
   except getopt.GetoptError:
      print './hosts.py -s <socket_path>'
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-h", "--help"):
         print './hosts.py -s <socket_path>'
         sys.exit()
      elif opt in ("-s", "--socket"):
         socket_path = arg
          
print 'Using socket "', socket_path

if __name__ == "__main__":
   main(sys.argv[1:])
    

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
print answer

# Parse the answer into a table (a list of lists)
#table = [ line.split(';') for line in answer.split('\n')[:-1] ]
#print table
