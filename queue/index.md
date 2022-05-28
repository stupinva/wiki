Многоэтапная многопроцессная обработка данных в Python
======================================================

Многопроцессная или многопоточная обработка данных в один этап является довольно тривиальной задачей, писать о которой нет необходимости. Хочу рассказать о многоэтапной обработке данных, когда задачи, обработанные одним пулом процессов, должны попадать на обработку в другой пул процессов.

Пример кода:

    #!/usr/bin/python
    # -*- coding: UTF-8 -*-
  
    from multiprocessing import Process, Queue
  
    def generator(name, input, output):
        for item in 'abcd':
            print name, item
            output.put(item)
        print name, 'exiting'
  
    def processor1(name, input, output):
        while True:
            item = input.get()
            if item is None:
                print name, 'exiting'
                break
            print name, item
            output.put(item)
  
    def processor2(name, input, output):
        while True:
            item = input.get()
            if item is None:
                print name, 'exiting'
                break
            print name, item
  
    class MultiProcessor(object):
        def __init__(self, name, num, function, input=None, output=None):
            self.num = num
            self.pool = []
            self.input = input
  
            for i in xrange(0, num):
                procname = '%s #%d' % (name, i + 1)
                p = Process(target=function, name=procname, args=(procname, input, output))
                p.start()
                self.pool.append(p)
  
        def stop(self):
            if self.input:
                for i in xrange(0, self.num):
                    self.input.put(None)
  
            for p in self.pool:
                p.join()
  
    input = Queue()
    output = Queue()
  
    p0 = MultiProcessor('generator', 1, generator, None, input)
    p1 = MultiProcessor('processor1', 2, processor1, input, output)
    p2 = MultiProcessor('processor2', 4, processor2, output)
  
    p0.stop()
    p1.stop()
    p2.stop()

Пример вывода программы:

    generator #1 a
    generator #1 b
    generator #1 c
    generator #1 d
    generator #1 exiting
    processor1 #1 a
    processor1 #2 b
    processor1 #2 c
    processor1 #2 d
    processor2 #1 b
    processor1 #2 exiting
    processor1 #1 exiting
    processor2 #1 c
    processor2 #1 d
    processor2 #1 a
    processor2 #1 exiting
    processor2 #3 exiting
    processor2 #2 exiting
    processor2 #4 exiting
    True
    True
