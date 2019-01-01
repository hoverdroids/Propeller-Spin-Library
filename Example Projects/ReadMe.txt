Do not simply throw an unzipped project into this folder! Instead, move dependencies to
the category folders so that other projects can use them. This allows us to see how the different
elements fit into the project so that we can grab just the components and not the integration.

If there are two files that have the same name, compare the files. If identical, delete the duplicate.
If the files are not the same, either integrate the duplicate into the current file or rename the duplicate
and update the project dependencies. This is because files cannot have the same name when using Brad's Spin Tool

If you merge the files, it's up to you to ensure there is no conflict between the old code and new.