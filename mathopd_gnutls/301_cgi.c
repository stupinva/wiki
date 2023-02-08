#include <stdio.h>
#include <stdlib.h>

int main (int argc, char** argv)
{
	printf("HTTP/1.1 301 Moved Permanently\nLocation: %s%s\n\n", getenv("MATHOPD_DESTINATION"), getenv("REQUEST_URI"));
}
