##
## EPITECH PROJECT, 2021
## libmy
## File description:
## Makefile automatically generated using Epine!
##

NAME = libmy.so

all: $(NAME) hello
.PHONY: all

__NAME__SRCS := $(shell find -path './src/*.c')
__NAME__OBJS := $(filter %.c,$(__NAME__SRCS))
__NAME__OBJS := $(__NAME__OBJS:.c=.o)
__NAME__DEPS := $(__NAME__OBJS:.o=.d)
$(NAME) $(__NAME__OBJS):
$(NAME): CPPFLAGS :=
$(NAME): CPPFLAGS += -MD -MP
$(NAME): CPPFLAGS += -I./include
$(NAME): CPPFLAGS += -DMY_ALLOW_FUN_MALLOC
$(NAME): CPPFLAGS += -DMY_ALLOW_FUN_FREE
$(NAME): CFLAGS :=
$(NAME): CFLAGS += -fPIC
$(NAME): CFLAGS += -Wall
$(NAME): CFLAGS += -Wextra
$(NAME): CFLAGS += $(if DEBUG,-g3)
$(NAME): LDLIBS :=
$(NAME): LDFLAGS :=
$(NAME): LDFLAGS += -shared
$(NAME): LDFLAGS += -L.
$(NAME): LDFLAGS += -Wl,-rpath .
$(NAME): $(__NAME__OBJS)
	@echo [shared] $@
	@$(CC) -o $@ $(__NAME__OBJS) $(LDFLAGS) $(LDLIBS)
-include $(__NAME__DEPS)

hello_SRCS := main.c
hello_OBJS := $(filter %.c,$(hello_SRCS))
hello_OBJS := $(hello_OBJS:.c=.o)
hello_DEPS := $(hello_OBJS:.o=.d)
hello $(hello_OBJS): libmy.so
hello: CPPFLAGS :=
hello: CPPFLAGS += -MD -MP
hello: CPPFLAGS += -I./include
hello: CFLAGS :=
hello: CFLAGS += -Wall
hello: CFLAGS += -Wextra
hello: CFLAGS += $(if DEBUG,-g3)
hello: LDLIBS :=
hello: LDLIBS += -lmy
hello: LDFLAGS :=
hello: LDFLAGS += -L.
hello: LDFLAGS += -Wl,-rpath .
hello: $(hello_OBJS)
	@echo [binary] $@
	@$(CC) -o $@ $(hello_OBJS) $(LDFLAGS) $(LDLIBS)
-include $(hello_DEPS)

%.o: %.c
	@echo [C] $@
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
%.o: %.cpp
	@echo [C++] $@
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

tests_run: ./unit_tests
	./unit_tests $(ARGS)
.PHONY: tests_run

clean:
	$(RM) $(__NAME__DEPS) $(__NAME__OBJS) $(hello_DEPS) $(hello_OBJS)
.PHONY: clean

fclean: clean
	$(RM) $(NAME) hello
	$(RM) ./unit_tests
.PHONY: fclean

re: fclean all
.PHONY: re
