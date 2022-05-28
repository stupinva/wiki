Функции rshift и and в BSD AWK
==============================

Понадобилось как-то воспользоваться парой функций GNU AWK, которых нет в BSD AWK. При этом ставить GNU AWK не хотелось. В итоге получились такие вот аналоги:

    function rshift(value, shift)
    {
      return value / (2 ** shift);
    }
  
    function and(value, mask)
    {
      new = 0;
      while (value > 0)
      {
        new = new * 2;
  
        value_bit = value % 2;
        mask_bit = mask % 2;
  
        if ((mask_bit == 1) && (value_bit == 1))
        {
          new = new + value_bit;
        }
  
        value = value / 2;
        mask = mask / 2;
      }
      return new;
    }
