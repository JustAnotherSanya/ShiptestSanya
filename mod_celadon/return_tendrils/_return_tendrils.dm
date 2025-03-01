/// name - название модпака. Используется для поиска других модпаков в init.
/// desc - описание для модпака. Может использоваться для списка глаголов модпака в качестве описания.
/// author - автор(ы) этого модпака.

/datum/modpack/return_tendrils
	name = "Возвращение спавнеров"
	desc = "Этот мод возвращает вырезаные спавнеры хайвботов, тендрилов в игру, а также ачивки связаные с ними."
	author = "MrCat15352"

/// Эти проки нужны, для того чтобы инициализировать датумы в определенный момент времени
/// сборки билда. Инициализация обновляет данные в билде повторно, перезаписывая новыми значениями
/// из модпака. Но иногда, сама инциализация есть и вызывается в кор коде в определенный момент, и
/// тогда такие проки не нужны и вовсе. Также проки не нужны если в модпаке только объекты находятся.
/// Если эти конструкции не нужны, просто закоментируй их!
/// (можешь использовать все три, но запуск билда увеличится на 0.1 сек, за каждый датум в модпаке)

// Инициализация ДО
/datum/modpack/return_tendrils/pre_initialize()
	. = ..()

// Инициализация ВОВРЕМЯ
/datum/modpack/return_tendrils/initialize()
	. = ..()

// Инициализация ПОСЛЕ
/datum/modpack/return_tendrils/post_initialize()
	. = ..()
