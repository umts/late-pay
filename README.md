Fill out Late Pay forms for export lines

1. Put the export lines in a file, `missing-lines.txt`
2. Download a copy of the roster
3. Copy `payroll_contact.yml.example` to `payroll_contact.yml` and edit

```
bundle exec ruby ./fill.rb
```
