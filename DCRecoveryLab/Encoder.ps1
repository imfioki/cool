#Encode Userdata into Base64
$EncodeUserData = [System.Text.Encoding]::UTF8.GetBytes($userDataString)
$userData = [System.Convert]::ToBase64String($EncodeUserData)
