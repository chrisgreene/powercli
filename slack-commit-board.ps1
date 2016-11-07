$slackURL = 'https://hooks.slack.com/services/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'
$commits_details = @()

$content = Invoke-WebRequest http://commitboard.gsstools.vmware.com/team/brm-entapps/#

$srs = $content.ParsedHtml.body.getElementsByClassName("commit_container")

$srs | % { 
  $sr = $_
  $commit_color = $sr.className.split(' ')[1]
  
  $supportRequestDetails = $sr.getElementsByClassName('supportrequest')[0]
  $title = $supportRequestDetails.getElementsByTagName('a')[0].title
  $sr_number = $supportRequestDetails.getElementsByTagName('a')[0].textContent
  $sr_href = $supportRequestDetails.getElementsByTagName('a')[0].href
  $tse_display_name = $sr.getElementsByTagName('a')[1].textContent
  $tse_username = $sr.getElementsByTagName('a')[1].nameProp
  $minutes_until_commit = $sr.getElementsByClassName('minutes')[0].getElementsByTagName('p')[0].innerText
  $minutes = $minutes_until_commit.split(' ')[0]
  #$hours_until_commit = "$([math]::floor($minutes / 60)):$(($minutes % 60).ToString('00'))"
  
  $commit_details = New-Object System.Object
  $commit_details | Add-Member -type NoteProperty -name CommitColor       -value $commit_color
  $commit_details | Add-Member -type NoteProperty -name Title             -value $title
  $commit_details | Add-Member -type NoteProperty -name SRNumber          -value $sr_number
  $commit_details | Add-Member -type NoteProperty -name SRHref            -value $sr_href
  $commit_details | Add-Member -type NoteProperty -name TSEDisplayName    -value $tse_display_name
  $commit_details | Add-Member -type NoteProperty -name TSEUsername       -value $tse_username
  $commit_details | Add-Member -type NoteProperty -name MinutesTillCommit -value $minutes_until_commit
  #$commit_details | Add-Member -type NoteProperty -name HoursTillCommit   -value $hours_until_commit
  
  $commits_details += $commit_details
  ($commit_color, $title, $sr_number, $sr_href, $tse_display_name, $tse_username, $minutes_until_commit) = $null
}

$commits_details | % {
  $commit_details = $_
  $slackPayload = "``$tse_display_name has a commit due at ``$minutes`` for ``SR#$sr_number`` Link:``$sr_href``" 
}

function postToSlack($slackPayload) {
   $jsonContent = @"
     {"channel": "@greenec", "username": "vRealize Automation", "text":"$($slackPayload)"}
   "@
   Invoke-WebRequest $slackURL -Method POST -ContentType 'application/json' -Body "'{"channel": "@greenec", "username": "vRealize Automation", "text":"$slackPayload"}'"
}