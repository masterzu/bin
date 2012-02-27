.. Directives Replace #####################################
.. |copy| unicode:: 0xA9 .. copyright sign
.. |--| unicode:: U+02013 .. en dash
.. |---| unicode:: U+02014 .. em dash
   :trim:
.. |...| unicode:: U+2026 .. ellipsis

.. |date| date:: 
.. |date annee| date:: %Y
.. |date c| date:: %c


.. Document ###############################################

Tools to repair the **mysqldump** error with encoding pb latin1/uft8

Process:

1. run ``split-sql.sh`` then the <file>.sql to split it in one per table file

2. a. run ``recode-sql-insert.sh <file>_SPLIT_xxx`` to scan the INSERT fields containing **Ã** character

2. b. run ``recode-sql-insert.sh <file>_SPLIT_xxx <f1> <f2>`` to recode as explain in *2.a.*

3. or run directly ``recode-sql-insert.sh -a <file>_SPLIT_xxx`` to scan and recode automaticly

.. vim: spelllang=en:

