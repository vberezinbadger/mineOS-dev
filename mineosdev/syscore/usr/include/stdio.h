// stdio.h
// You may have been expecting a minimal one, but look what you got: one!

void printf(const char* str) {
  lua_execute("io.write", str); // Function to interface with Lua things
}
