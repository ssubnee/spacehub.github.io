document.addEventListener('DOMContentLoaded', function() {
    var dropdown1 = document.getElementById('standard');
    var dropdown2 = document.getElementById('infra-big');
    var dropdown3 = document.getElementById('infra-small');
    var elementToActivate = document.getElementById('elementToActivate');

    dropdown1.addEventListener('change', checkConditions);
    dropdown2.addEventListener('change', checkConditions);
    dropdown3.addEventListener('change', checkConditions);

    function checkConditions() {
        var selectedOption1 = dropdown1.value;
        var selectedOption2 = dropdown2.value;
        var selectedOption3 = dropdown3.value;

        // 원하는 조건에 따라 요소를 활성화 또는 비활성화합니다.
        if (selectedOption1 === '주요정보통신기반시설 취약점 분석평가 기준' && selectedOption2 === 'Networks') {
            elementToActivate.style.display = 'block'; // 활성화
        } else {
            elementToActivate.style.display = 'none'; // 비활성화
        }
    }
});