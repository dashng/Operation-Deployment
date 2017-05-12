class Test():
	def __init__(self):
		pass

	def run(self):
		print '======'

	def walk(self):
		print 'walk...'

t = Test()



class Proxy(object):
    def __new__(cls, t):
    	# print t, cls
        # return super(Proxy, cls).__new__(cls)
        return t

    def __init__(self, t):
        print "INIT"

a = Proxy(t)

if __name__ == "__main__":
    a.run()
    a.walk()
