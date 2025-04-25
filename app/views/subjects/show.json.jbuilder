if @subject
	json.partial! "subjects/subject", subject: @subject
else
	json.error 'No encontrado'
end