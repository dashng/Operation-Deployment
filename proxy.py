class Test():
	def __init__(self):
		pass

	def run(self):
		print '======'

	def walk(self):
		print 'walk...'


class Proxy(object):
    def __new__(cls, t):
    	# print t, cls
        # return super(Proxy, cls).__new__(cls)
        return t

    def __init__(self, t):
        print "INIT"


if __name__ == "__main__":
	test = Test()
	proxy = Proxy(test)
	proxy.run()
	proxy.walk()
