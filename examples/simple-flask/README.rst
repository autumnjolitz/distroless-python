===================
simple flask app
===================

Install Flask using pip. Run in safe pip-less environment.

.. code:: bash

    $ cd examples/simple-flask/
    $ 2>/dev/null docker build -t hello .
    $ docker images hello
    REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
    hello        latest    d5108767e49e   15 seconds ago   32.4MB
    $ docker run -p8080:8080 --rm -it hello
     * Serving Flask app 'hello'
     * Debug mode: off
    WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
     * Running on all addresses (0.0.0.0)
     * Running on http://127.0.0.1:8080
     * Running on http://172.17.0.2:8080
    Press CTRL+C to quit
    192.168.65.1 - - [03/Aug/2024 06:37:49] "GET / HTTP/1.1" 200 -
    ^C
    $
