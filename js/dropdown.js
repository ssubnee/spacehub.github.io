document.addEventListener('DOMContentLoaded', function() {
    var dropdown1 = document.getElementById('standard');
    var dropdown2 = document.getElementById('infra1');
    var dropdown3 = document.getElementById('infra2');
    
    // 드롭다운 2의 옵션을 가져와 배열에 저장
    var dropdown2Options = dropdown2.options;
    var dropdown3Options = dropdown3.options;

    dropdown1.addEventListener('change', function() {
        var selectedOption1 = dropdown1.value;
        var selectedOption2 = dropdown2.value;
        
        // 이전에 선택된 옵션들을 모두 활성화
        for (var i = 0; i < dropdown2Options.length; i++) {
            dropdown2Options[i].disabled = false;
        }
        // 이전에 선택된 옵션들을 모두 활성화
        for (var i = 0; i < dropdown3Options.length; i++) {
            dropdown3Options[i].disabled = false;
        }
        
        if (selectedOption2 === 'DBMS') {
            // 'a'가 선택된 경우, 특정 옵션들을 비활성화
            dropdown3Options[1].disabled = true;
            dropdown3Options[2].disabled = true;
            dropdown3Options[8].disabled = true;
        }
    });
});