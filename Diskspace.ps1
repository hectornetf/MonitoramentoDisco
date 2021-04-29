Param (
# Na variavel computers se define o hostname da maquina a ser monitorada  
$computers = ("Serv-01","Serv-02"),
# Na variavel names eu defino a finalidade do servidor, importante inserir novos servidores sempre no final do vetor em ambos os parametros
$names = ("SV-01","SV-02")
) 

 
$head = @"
<style>
body { background-color:#FFFFFF;
       font-family:Tahoma;
       font-size:8pt; }
td, th { border:1px solid #000033; 
         border-collapse:collapse; }
th { color:white;
     background-color:#000033; }
table, tr, td, th { padding: 0px; margin: 0px }
table { margin-left:8px; }
</style>
<Title>$Title</Title>
"@ 
$count=0
$fragments=@()
 
$data=Get-WmiObject -Class Win32_logicaldisk -filter "drivetype=3" -computer $computers -ErrorAction SilentlyContinue
 
$groups=$Data | Group-Object -Property SystemName 
 
[string]$g=[char]9608  
         
ForEach ($computer in $groups) { 

    $fragments+="<b>$($computer.Name) - $($names[$count]) </b>"
     
    $Drives=$computer.group 

    $html=$drives | Select @{Name="Drive";Expression={$_.DeviceID}}, 
    @{Name=" Total GB ";Expression={$_.Size/1GB  -as [int]}}, 
    @{Name=" Usado GB ";Expression={"{0:N2}" -f (($_.Size - $_.Freespace)/1GB) }}, 
    @{Name=" Livre GB ";Expression={"{0:N2}" -f ($_.FreeSpace/1GB) }}, 
    @{Name="Gráfico";Expression={ 
      $UsedPer= (($_.Size - $_.Freespace)/$_.Size)*100 
      $UsedGraph=$g * ($UsedPer/2) 
      $FreeGraph=$g* ((100-$UsedPer)/2) 
	  
      "xopenFont color=Redxclose{0}xopen/FontxclosexopenFont Color=Greenxclose{1}xopen/fontxclose" -f $usedGraph,$FreeGraph 
    }} | ConvertTo-Html -Fragment 
     
    $html=$html -replace "xopen","<" 
    $html=$html -replace "xclose",">" 
      
    $Fragments+=$html
    $count++
     
}
 
$footer=("<br><I>Ultima Geração em {0} by {1}\{2}<I>" -f (Get-Date -displayhint date),$env:userdomain,$env:username) 
$fragments+=$footer 

ConvertTo-Html -head $head -body $fragments $servername | Out-File C:\Monitoramento\serverdiscos.html

#################################################################################################################

$Arquivo = Get-Content 'C:\Monitoramento\serverdiscos.html'

$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
$Username = "teste@gmail.com.br"
$Password = "abc123"

$to = "teste1@gmail.com.br"
$cc = "teste2@gmail.com.br"
$cc1 = "teste2@gmail.com.br"
$subject = "Monitoramento - Servidores"
$body = $Arquivo

$message = New-Object System.Net.Mail.MailMessage
$message.subject = $subject
$message.body = $body
$message.IsBodyHtml = $true
$message.to.add($to)
$message.cc.add($cc)
$message.cc.add($cc1)
$message.from = $username

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$smtp.send($message)
write-host "E-mail enviado"