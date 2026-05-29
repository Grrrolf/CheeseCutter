module com.config;

version(Windows) {
	enum char DIR_SEPARATOR = '\\';
}
else {
	enum char DIR_SEPARATOR = '/';
}
