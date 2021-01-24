# Contribution guidelines

We’ll keep this simple:

**Code …**

## … submissions

Please make all your pull requests against the [`develop` branch][develop] (this
is the default branch). No other pull requests will be accepted.

Please ensure all tests pass by running `make test`, and ideally `R CMD check`.

All new functions, also un-exported ones, *must* be documented (documentation
for un-exported functions should contain the `@keywords internal` tag).

## … style

* Generally try to be consistent with the prevailing style in this
  project.
* Don’t use dots (`.`) in identifiers, except for S3 dispatch; use underscore
  (`_`) to separate words.
* Never `"string-quote"` identifiers; when using invalid identifiers, use
  `` `backtick quotes` `` instead.
* Use `=` assignments, not `<-`.
* Indentation is by four spaces.
* R files must end in `.r` — no capital letters in file extensions, please.
* Don’t waste vertical space: use empty lines judiciously; don’t put opening
  braces on their own lines, and keep individual functions at a reasonable
  maximum length.

## … of conduct

Be polite, respect other contributors. In discussions, assume good faith in
others. If you’re unsure, please refer to the [Contributor Covenant Code of
Conduct][cccoc].

[cccoc]: http://contributor-covenant.org/version/1/4/
[develop]: https://github.com/klmr/modules/tree/develop
