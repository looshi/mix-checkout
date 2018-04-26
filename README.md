# mix-checkout

Description:
Mix task which runs Ecto migrations when switching branches.

Installation:
For use in the Phoenix Framework, copy this file to your lib/mix/tasks folder.

Usage:
`mix checkout branch-name`

How it works:
Looks in the migrations folder and finds the common ancestor between
your current branch and the branch you'd like to checkout.
Rolls back the current branch to the common ancestor, then checks out the
new branch and migrates forward.
If both branches are at the same migration this task will not try to run
any rollbacks or migrations.

Why:
Useful for projects where the schema changes often and you need to switch back
and forth between branches which contain different schemas.
