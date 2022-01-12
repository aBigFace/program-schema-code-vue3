import { ref } from 'vue';
export default function useHello() {
	const test = ref(10);
	return {
		test,
	};
}
