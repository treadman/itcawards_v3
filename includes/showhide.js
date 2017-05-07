function showThis(id)
	{
		 if (document.all)
			 {
				  document.getElementById(id).style.display = 'inline';
			 }
		 else
			{
				  document.getElementById(id).style.display = 'table-row';
			}
	}

function hideThis(id)
	{
		document.getElementById(id).style.display = 'none';
	}
