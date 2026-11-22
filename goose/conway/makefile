lib:
	@goose -O2 --standalone --header pybind.h -o pybind.c pybind.goose
	@gcc -O3 -shared -fPIC -o libconway.so pybind.c alloc_copy.c

	@python3 poly_ui.py
ui:
	@python3 poly_ui.py
clean:
	@rm -fr pybind.c pybind.h pybind.o alloc_copy.o *.so johnson.c johnson.o
