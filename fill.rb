require 'date'
require 'csv'
require 'fillable-pdf'
require 'yaml'

ExportEntry = Struct.new(:empl_id, :record, :date, :trc, :hours, :name, :rate, :st)
roster = CSV.parse(File.read('UMTL514_Roster_A835600.csv'))
payroll_contact = YAML.load(File.read('payroll_contact.yml'))

trc_fields = [11, 21, 37, 47, 57, 67].map { |n| :"Text#{n}" }
total_fields = [19, 29, 45, 55, 65, 75].map { |n| :"Text#{n}" }
end_date_fields = [20, 36, 46, 56, 66, 76].map { |n| :"Text#{n}" }
date_fields = [12, 22, 38, 48, 58, 68].map do |m|
  7.times.map { |n| :"Text#{m+n}" }
end

entries = File.read('missing-lines.txt').lines.map do |line|
  empl_id = line[0,8]
  record = line[11,3].to_i

  roster_line = roster.find{|l| l[0] == empl_id && l[1].to_i == record}
  any_roster_line = roster.find{|l| l[0] == empl_id}
  name = any_roster_line && any_roster_line[2]
  rate = roster_line && roster_line[6]
  st = roster_line && roster_line[5]


  ExportEntry.new(empl_id, record, Date.parse(line[14,10]), line[24,5].strip, line[29,19].to_f, name, rate, st)
end.group_by { |e| [e.empl_id, e.record, e.name, e.rate, e.st] }

entries.each do |(empl_id, record, name, rate, st), data|
  pdf = FillablePDF.new('late-pay.pdf')
  pdf.set_field(:Text1, empl_id)
  pdf.set_field(:Text3, record)
  pdf.set_field(:Text5, name)
  pdf.set_field(:Text6, 'Transportation Services')
  pdf.set_field(:Text7, 'A835600')
  pdf.set_field(:Text8, st)
  pdf.set_field(:Text9, rate)

  puts "Missing Combocode/rate for #{empl_id} / #{record}" if (st.nil? || rate.nil?) && !(record == 999)

  data.group_by(&:trc).each.with_index do |(trc, rows), i|
    total = 0.0
    pdf.set_field(trc_fields[i], trc)

    rows.each do |row|
      pdf.set_field(date_fields[i][row.date.wday], row.hours)
      total += row.hours
    end

    pdf.set_field(total_fields[i], total)
    pdf.set_field(end_date_fields[i], Date.new(2022,5,14).to_s)
  end

  pdf.set_field(:Text77, payroll_contact['name'])
  pdf.set_field(:Text78, payroll_contact['email'])
  pdf.set_field(:Text79, payroll_contact['phone'])
  pdf.set_field(:Text80, Date.today)

  pdf.save_as("output/late-pay-#{empl_id}-#{record}.pdf")
end
